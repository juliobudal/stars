# frozen_string_literal: true

require "rails_helper"

# End-to-end behavior of the judge cycle inside Generators::Base. The
# generator runs `generate → judge → (regenerate if REVISE/FAIL within
# budget) → ship`. These specs prove all three branches.
RSpec.describe Academy::Lens::Generators::Scientific do
  let(:concept) do
    build_stubbed(
      :academy_concept,
      slug: "dopamina", name: "Dopamina",
      definition: "neurotransmissor da expectativa",
      category: "cognitivo"
    )
  end

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
        "options" => ["Receber um like que você já esperava receber", "Ver que tem uma notificação sem saber ainda de quem é", "Ler cem mensagens em ordem cronológica"],
        "correct_index" => 1,
        "rationale" => "Quanto maior a incerteza sobre a recompensa, maior o pico de dopamina antes de saber o resultado."
      }
    }
  end

  let(:llm)   { instance_double(Academy::Llm::Client) }
  let(:judge) { instance_double(Academy::Llm::Judge) }

  before do
    Academy.config.judge_enabled = true
    Academy.config.judge_max_revision_cycles = 1
    allow(Academy::Llm::Judge).to receive(:new).and_return(judge)
  end

  def llm_returns(payload)
    {
      content: payload.to_json,
      raw: { "usage" => { "prompt_tokens" => 100, "completion_tokens" => 200 }, "model" => "deepseek-mock" }
    }
  end

  describe "judge returns PASS on first generation" do
    it "ships without regenerating and stamps the cache row with PASS" do
      allow(llm).to receive(:chat).and_return(llm_returns(valid_payload))
      allow(judge).to receive(:judge).and_return(
        Academy::Llm::Judge::Verdict.new(
          score: 95, verdict: "PASS",
          critique: nil, rewrite_hint: nil,
          factual_issue: nil, concept_drift: nil, safety_issue: nil,
          raw_json: {}
        )
      )

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:judge_verdict]).to eq("PASS")
      expect(result.data[:judge_overall_score]).to eq(95)
      expect(result.data[:judge_revision_cycles]).to eq(0)
      expect(llm).to have_received(:chat).once
      expect(judge).to have_received(:judge).once
    end
  end

  describe "judge returns REVISE, second generation passes" do
    it "calls the LLM twice, feeds rewrite_hint back, and ships PASS" do
      revise = Academy::Llm::Judge::Verdict.new(
        score: 65, verdict: "REVISE",
        critique: "Drift de conceito leve.",
        rewrite_hint: "Ancore o passo 2 explicitamente em 'expectativa antes da recompensa'.",
        factual_issue: nil, concept_drift: "sacada cai em 'vício' genérico", safety_issue: nil,
        raw_json: {}
      )
      pass = Academy::Llm::Judge::Verdict.new(
        score: 92, verdict: "PASS",
        critique: nil, rewrite_hint: nil,
        factual_issue: nil, concept_drift: nil, safety_issue: nil,
        raw_json: {}
      )
      chat_calls = []
      allow(llm).to receive(:chat) do |**kwargs|
        chat_calls << kwargs
        llm_returns(valid_payload)
      end
      allow(judge).to receive(:judge).and_return(revise, pass)

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:judge_verdict]).to eq("PASS")
      expect(result.data[:judge_revision_cycles]).to eq(1)
      expect(chat_calls.length).to eq(2)
      expect(judge).to have_received(:judge).twice

      # The 2nd LLM call must include the judge feedback + rewrite hint.
      second_user = chat_calls[1][:messages].last[:content]
      expect(second_user).to include("avaliada pelo juiz factual")
      expect(second_user).to include("Ancore o passo 2 explicitamente")
    end
  end

  describe "judge keeps returning REVISE past the cycle budget" do
    it "ships the last attempt with REVISE recorded" do
      revise = Academy::Llm::Judge::Verdict.new(
        score: 60, verdict: "REVISE",
        critique: "Ainda fraco.", rewrite_hint: "Mais ancoragem no conceito.",
        factual_issue: nil, concept_drift: "drift persistente", safety_issue: nil,
        raw_json: {}
      )
      allow(llm).to receive(:chat).and_return(llm_returns(valid_payload))
      allow(judge).to receive(:judge).and_return(revise, revise)

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:judge_verdict]).to eq("REVISE")
      expect(result.data[:judge_revision_cycles]).to eq(1)
      expect(result.data[:judge_critique]).to eq("Ainda fraco.")
      expect(llm).to have_received(:chat).twice
      expect(judge).to have_received(:judge).twice
    end
  end

  describe "judge is unreachable" do
    it "ships with judge_verdict='skipped' rather than blocking the kid" do
      allow(llm).to receive(:chat).and_return(llm_returns(valid_payload))
      allow(judge).to receive(:judge).and_raise(Academy::Llm::Judge::JudgeError, "503")

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:judge_verdict]).to eq("skipped")
      expect(result.data[:judge_revision_cycles]).to eq(0)
    end
  end

  describe "judge disabled globally" do
    it "behaves like the old path — no judge call, no judge_verdict" do
      Academy.config.judge_enabled = false
      allow(llm).to receive(:chat).and_return(llm_returns(valid_payload))
      allow(judge).to receive(:judge) # stub so we can assert it wasn't called

      result = described_class.call(concept: concept, llm: llm)
      expect(result.success?).to be true
      expect(result.data[:judge_verdict]).to be_nil
      expect(judge).not_to have_received(:judge)
    end
  end
end
