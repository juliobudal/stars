# frozen_string_literal: true

require "rails_helper"

# Cross-reference guard: schema-valid JSON can still drift between
# `mapping[].from/to` and the elements lists. Subclass surfaces that as
# SchemaInvalid so Base's existing single retry kicks in with a message
# that names the exact offender.
RSpec.describe Academy::Lens::Generators::AnalogyBridge do
  let(:concept) do
    build_stubbed(
      :academy_concept,
      slug: "senso-critico", name: "Senso crítico",
      definition: "capacidade de avaliar afirmações antes de aceitá-las",
      category: "cognitivo"
    )
  end

  let(:source_elements) do
    [
      "anticorpo que reconhece padrão antigo",
      "antígeno apresentado pela primeira vez",
      "memória imunológica acumulada ao longo do tempo",
      "vacina dada antes do contato real com a doença"
    ]
  end

  let(:target_elements) do
    [
      "ceticismo treinado contra um padrão comum",
      "afirmação inédita encontrada no feed",
      "experiência prévia que serve de referência",
      "argumento exposto antes do confronto público"
    ]
  end

  let(:valid_payload) do
    {
      "source_domain" => { "name" => "Sistema imune adaptativo", "elements" => source_elements },
      "target_domain" => { "name" => "Repertório de pensamento crítico", "elements" => target_elements },
      "mapping" => [
        { "from" => source_elements[0], "to" => target_elements[0] },
        { "from" => source_elements[1], "to" => target_elements[1] },
        { "from" => source_elements[2], "to" => target_elements[2] }
      ],
      "transfer_question" => "Onde {{learner_name}} já viu uma reação alérgica a uma ideia nova rolar na escola dele?"
    }
  end

  before do
    Academy.config.judge_enabled = false
  end

  def llm_returns(payload)
    { content: payload.to_json, raw: { "usage" => { "prompt_tokens" => 100, "completion_tokens" => 200 }, "model" => "mock" } }
  end

  describe "happy path" do
    it "passes when every mapping.from/to is a literal item of the matching elements list" do
      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(llm_returns(valid_payload))

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:payload]).to eq(valid_payload)
    end
  end

  describe "drift on a single mapping.to" do
    it "retries once and succeeds when the second attempt is clean" do
      drifted = valid_payload.deep_dup
      drifted["mapping"][0]["to"] = "ceticismo levemente treinado, agora com outra palavra"

      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(
        llm_returns(drifted),
        llm_returns(valid_payload)
      )

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:payload]).to eq(valid_payload)
      expect(llm).to have_received(:chat).twice
    end
  end

  describe "drift on both attempts" do
    it "fails with :llm_schema_invalid and names the offending list" do
      drifted = valid_payload.deep_dup
      drifted["mapping"][0]["from"] = "anticorpo escrito com outra palavra qualquer"

      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(llm_returns(drifted))

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_schema_invalid)
      expect(result.data[:errors].join).to include("source_domain.elements")
    end
  end
end
