# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Llm::Judge do
  let(:concept) do
    build_stubbed(
      :academy_concept,
      slug: "dopamina", name: "Dopamina",
      definition: "neurotransmissor da expectativa",
      category: "cognitivo"
    )
  end

  let(:payload) do
    {
      "headline" => "Dopamina sobe ANTES da recompensa chegar mesmo",
      "mechanism_steps" => ["a", "b", "c"],
      "illustration_hint" => "uma onda que sobe…",
      "micro_check" => {
        "question" => "?", "options" => %w[a b c], "correct_index" => 0, "rationale" => "..."
      }
    }
  end

  let(:client) { instance_double(Academy::Llm::Client) }
  let(:judge)  { described_class.new(client: client) }

  describe "happy path — PASS verdict" do
    it "parses the JSON and returns a PASS Verdict" do
      response = {
        "score" => 95,
        "verdict" => "PASS",
        "factual_issue" => nil,
        "concept_drift" => nil,
        "safety_issue" => nil,
        "critique" => nil,
        "rewrite_hint" => nil
      }
      allow(client).to receive(:chat).and_return(content: response.to_json)

      verdict = judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      expect(verdict).to be_pass
      expect(verdict.score).to eq(95)
      expect(verdict.unsafe?).to be false
      expect(verdict.needs_revision?).to be false
    end
  end

  describe "REVISE verdict (concept drift, no safety issue)" do
    it "flags needs_revision and surfaces the rewrite hint" do
      response = {
        "score" => 65,
        "verdict" => "REVISE",
        "factual_issue" => nil,
        "concept_drift" => "Lente ensina 'vício' genérico em vez de 'dopamina'.",
        "safety_issue" => nil,
        "critique" => "Drift de conceito: sacada não é específica de dopamina.",
        "rewrite_hint" => "Reescreva o headline e o passo 2 ancorando explicitamente em 'expectativa antes da recompensa'."
      }
      allow(client).to receive(:chat).and_return(content: response.to_json)

      verdict = judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      expect(verdict).to be_revise
      expect(verdict.needs_revision?).to be true
      expect(verdict.concept_drift).to match(/vício/)
      expect(verdict.rewrite_hint).to match(/expectativa/)
    end
  end

  describe "FAIL verdict (safety violation forces FAIL)" do
    it "reports needs_revision and unsafe? true" do
      response = {
        "score" => 20,
        "verdict" => "FAIL",
        "factual_issue" => nil,
        "concept_drift" => nil,
        "safety_issue" => "Cena descreve auto-dano sem necessidade pedagógica.",
        "critique" => "Conteúdo inapropriado pra 7-12.",
        "rewrite_hint" => "Substitua a cena por exemplo cotidiano não-violento."
      }
      allow(client).to receive(:chat).and_return(content: response.to_json)

      verdict = judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      expect(verdict).to be_fail
      expect(verdict.needs_revision?).to be true
      expect(verdict.unsafe?).to be true
      expect(verdict.safety_issue).to match(/auto-dano/)
    end
  end

  describe "FAIL verdict (hallucination)" do
    it "marks factual_issue and forces revision" do
      response = {
        "score" => 30,
        "verdict" => "FAIL",
        "factual_issue" => "Cita 'estudo da OMS de 2024' que não existe.",
        "concept_drift" => nil,
        "safety_issue" => nil,
        "critique" => "Fonte inventada.",
        "rewrite_hint" => "Substitua a fonte por estimativa honestamente declarada."
      }
      allow(client).to receive(:chat).and_return(content: response.to_json)

      verdict = judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      expect(verdict).to be_fail
      expect(verdict.unsafe?).to be false
      expect(verdict.factual_issue).to match(/OMS/)
    end
  end

  describe "tolerant JSON extraction" do
    it "parses JSON wrapped in markdown fences" do
      raw = "```json\n{\"score\":90,\"verdict\":\"PASS\",\"factual_issue\":null,\"concept_drift\":null,\"safety_issue\":null,\"critique\":null,\"rewrite_hint\":null}\n```"
      allow(client).to receive(:chat).and_return(content: raw)
      verdict = judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      expect(verdict).to be_pass
      expect(verdict.score).to eq(90)
    end
  end

  describe "transport / parse errors" do
    it "raises JudgeError on LLM transport failure" do
      allow(client).to receive(:chat).and_raise(Academy::Llm::Client::Error, "boom")
      expect {
        judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      }.to raise_error(Academy::Llm::Judge::JudgeError, /boom/)
    end

    it "raises JudgeError on unparseable response" do
      allow(client).to receive(:chat).and_return(content: "not json at all")
      expect {
        judge.judge(concept: concept, lens_type: :scientific, payload: payload)
      }.to raise_error(Academy::Llm::Judge::JudgeError, /invalid JSON/)
    end
  end
end
