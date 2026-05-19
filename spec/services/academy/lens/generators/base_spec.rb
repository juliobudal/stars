# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Generators::Base do
  let(:concept) { build_stubbed(:academy_concept, slug: "dopamina", name: "Dopamina", definition: "neurotransmissor da expectativa", category: "cognitivo") }

  let(:valid_payload) do
    {
      "headline" => "Dopamina sobe ANTES da recompensa chegar mesmo",
      "mechanism_steps" => [
        "Você ouve o notify e o cérebro libera dopamina antes de você abrir.",
        "Abrir o app não dá mais dopamina — só apaga o pico anterior.",
        "Por isso o segundo refresh já parece menos do que o primeiro."
      ],
      "illustration_hint" => "Visualize uma onda que sobe rápido com a expectativa e despenca assim que a recompensa chega — é o ANTES, não o depois.",
      "micro_check" => {
        "question" => "Qual destas situações solta MAIS dopamina antecipatória?",
        "options" => [ "Receber um like que você já esperava receber", "Ver que tem uma notificação sem saber ainda de quem é", "Ler cem mensagens em ordem cronológica" ],
        "correct_index" => 1,
        "rationale" => "Quanto maior a incerteza sobre a recompensa, maior o pico de dopamina antes de saber o resultado."
      }
    }
  end

  describe "happy path" do
    it "calls the LLM, parses JSON, validates schema, and returns payload" do
      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(
        content: valid_payload.to_json,
        raw: { "usage" => { "prompt_tokens" => 120, "completion_tokens" => 220 }, "model" => "deepseek-mock" }
      )

      result = Academy::Lens::Generators::Scientific.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:payload]).to eq(valid_payload)
      expect(result.data[:tokens_in]).to eq(120)
      expect(result.data[:tokens_out]).to eq(220)
      expect(result.data[:model_id]).to eq("deepseek-mock")
    end
  end

  describe "LLM transport error" do
    it "fails with :llm_transport_error" do
      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_raise(Academy::Llm::Client::Error, "boom")

      result = Academy::Lens::Generators::Scientific.call(concept: concept, llm: llm)
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_transport_error)
    end
  end

  describe "LLM returns malformed JSON" do
    it "fails with :llm_invalid_json" do
      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(content: "not json", raw: {})

      result = Academy::Lens::Generators::Scientific.call(concept: concept, llm: llm)
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_invalid_json)
    end
  end

  describe "LLM output fails the per-type schema" do
    it "fails with :llm_schema_invalid and lists schema errors" do
      llm = instance_double(Academy::Llm::Client)
      bad_payload = valid_payload.merge("mechanism_steps" => [ "só um passo" ])
      allow(llm).to receive(:chat).and_return(content: bad_payload.to_json, raw: {})

      result = Academy::Lens::Generators::Scientific.call(concept: concept, llm: llm)
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_schema_invalid)
      expect(result.data[:errors]).to be_an(Array)
      expect(result.data[:errors]).not_to be_empty
    end
  end

  describe "Generators.for(:type)" do
    it "returns the matching subclass" do
      expect(Academy::Lens::Generators.for(:scientific)).to eq(Academy::Lens::Generators::Scientific)
      expect(Academy::Lens::Generators.for(:analogy_bridge)).to eq(Academy::Lens::Generators::AnalogyBridge)
    end

    it "raises ArgumentError on unknown" do
      expect { Academy::Lens::Generators.for(:imaginary) }.to raise_error(ArgumentError, /Unknown/)
    end
  end

  describe "concept-specific forbidden_terms enforcement" do
    let(:dopamina) do
      build_stubbed(
        :academy_concept,
        slug: "dopamina", name: "Dopamina",
        definition: "neurotransmissor da expectativa", category: "cognitivo"
      ).tap do |c|
        # forbidden_terms_list reads via `attributes[]`, so we stub the attr.
        allow(c).to receive(:attributes).and_return(
          c.attributes.merge("forbidden_terms" => ["molécula do prazer"])
        )
      end
    end

    it "rejects payloads containing a concept-specific forbidden term and retries" do
      offending = valid_payload.merge(
        "illustration_hint" => "É a molécula do prazer flutuando no cérebro feliz e contente sempre.",
      )
      clean = valid_payload

      llm = instance_double(Academy::Llm::Client)
      # First call: violates → retry. Second call: clean.
      allow(llm).to receive(:chat).and_return(
        { content: offending.to_json, raw: {} },
        { content: clean.to_json, raw: { "usage" => {}, "model" => "mock" } }
      )

      result = Academy::Lens::Generators::Scientific.call(concept: dopamina, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:payload]).to eq(clean)
    end

    it "fails with :llm_tone_violation when both attempts violate the forbidden term" do
      offending = valid_payload.merge(
        "illustration_hint" => "É a molécula do prazer flutuando no cérebro feliz e contente sempre.",
      )

      llm = instance_double(Academy::Llm::Client)
      allow(llm).to receive(:chat).and_return(content: offending.to_json, raw: {})

      result = Academy::Lens::Generators::Scientific.call(concept: dopamina, llm: llm)
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_tone_violation)
    end
  end
end
