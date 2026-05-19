# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Generators::Base do
  let(:concept) { create(:academy_concept, slug: "base-concept", category: "cognitivo") }
  let(:llm) { instance_double(Academy::Llm::Client) }

  # A throwaway subclass that pins lens_type but doesn't load real prompts.
  let(:generator_class) do
    klass = Class.new(described_class)
    klass.lens_type = :scientific
    stub_const("FakeGenerator", klass)
    klass
  end

  def llm_response(content)
    { content: content, raw: { "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20 }, "model" => "fake/m" } }
  end

  def valid_payload
    {
      "headline" => "Como esse mecanismo realmente funciona aqui",
      "mechanism_steps" => [
        "Primeiro passo causal: o estímulo atinge o sistema e dispara o sinal inicial.",
        "Segundo passo: o sinal se propaga e ativa a próxima camada de resposta.",
        "Terceiro passo: a resposta final se manifesta no comportamento observável."
      ],
      "illustration_hint" => "Uma metáfora visual rica: bolinhas coloridas passando por um labirinto de tubos, mudando de cor a cada curva.",
      "micro_check" => {
        "question" => "Quando o estímulo aparece, qual é o próximo passo concreto que acontece?",
        "options" => [
          "Nada acontece imediatamente, é só depois.",
          "O sinal inicial se propaga pela camada seguinte.",
          "O comportamento já se manifesta direto."
        ],
        "correct_index" => 1,
        "rationale" => "O sinal precisa se propagar antes do comportamento aparecer — é uma cadeia causal explícita."
      }
    }
  end

  context "happy path" do
    it "returns payload + prompt_digest + mastery_tier on success" do
      expect(llm).to receive(:chat).once.and_return(llm_response(valid_payload.to_json))
      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).to be_success
      expect(result.data[:payload]).to eq(valid_payload)
      expect(result.data[:prompt_digest]).to match(/^[a-f0-9]{8}$/)
      expect(result.data[:mastery_tier]).to eq("any")
    end

    it "uses per-lens temperature + max_tokens from Catalog" do
      expect(llm).to receive(:chat).with(
        hash_including(temperature: 0.4, max_tokens: 10_000)
      ).and_return(llm_response(valid_payload.to_json))
      generator_class.new(concept: concept, llm: llm).call
    end
  end

  context "retry on JSON parse failure" do
    it "retries once with the parse error fed back, then succeeds" do
      first_call_args = nil
      second_call_args = nil
      call_count = 0
      allow(llm).to receive(:chat) do |args|
        call_count += 1
        if call_count == 1
          first_call_args = args
          { content: "not json at all", raw: {} }
        else
          second_call_args = args
          llm_response(valid_payload.to_json)
        end
      end

      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).to be_success
      expect(call_count).to eq(2)
      expect(second_call_args[:messages].last[:content]).to include("JSON válido")
    end

    it "fails after the retry also fails" do
      allow(llm).to receive(:chat).and_return({ content: "still garbage", raw: {} })
      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).not_to be_success
      expect(result.error).to eq(:llm_invalid_json)
    end
  end

  context "tone post-check" do
    it "retries when output contains a forbidden phrase" do
      bad_payload = valid_payload.merge("headline" => "Reflita sobre isso por um momento")
      call_count = 0
      allow(llm).to receive(:chat) do |args|
        call_count += 1
        if call_count == 1
          llm_response(bad_payload.to_json)
        else
          expect(args[:messages].last[:content]).to include("violou o tom")
          llm_response(valid_payload.to_json)
        end
      end
      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).to be_success
      expect(call_count).to eq(2)
    end

    it "fails with :llm_tone_violation if both attempts violate" do
      bad_payload = valid_payload.merge("illustration_hint" => "Você sabia que isso é importante?")
      allow(llm).to receive(:chat).and_return(llm_response(bad_payload.to_json))
      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).not_to be_success
      expect(result.error).to eq(:llm_tone_violation)
    end
  end

  context "schema-invalid retry" do
    it "retries with the validator errors fed back" do
      bad_payload = valid_payload.merge("mechanism_steps" => [ "só um passo" ])
      call_count = 0
      allow(llm).to receive(:chat) do |args|
        call_count += 1
        if call_count == 1
          llm_response(bad_payload.to_json)
        else
          expect(args[:messages].last[:content]).to include("schema")
          llm_response(valid_payload.to_json)
        end
      end
      result = generator_class.new(concept: concept, llm: llm).call
      expect(result).to be_success
      expect(call_count).to eq(2)
    end
  end

  it "exposes a stable prompt_digest derived from the template" do
    gen = generator_class.new(concept: concept, llm: llm)
    expect(gen.prompt_digest).to eq(gen.prompt_digest)
    expect(gen.prompt_digest).to match(/^[a-f0-9]{8}$/)
  end
end
