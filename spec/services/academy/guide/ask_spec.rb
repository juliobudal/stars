# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::Ask do
  let(:concept) { create(:academy_concept) }
  let(:mission) { create(:academy_mission, concept: concept, central_insight: "Custo da troca é caro.") }
  let(:learner) { Academy::Learner.new(id: 333, display_name: "Theo", age_band: "kid", timezone: "America/Sao_Paulo") }

  let(:client) { instance_double(Academy::Llm::Client) }

  before do
    allow(Academy).to receive(:configured?).and_return(true)
  end

  def llm_response(content, in_tokens: 50, out_tokens: 30)
    {
      content: content,
      raw: { "usage" => { "prompt_tokens" => in_tokens, "completion_tokens" => out_tokens } },
      tokens: in_tokens + out_tokens
    }
  end

  it "happy path: persists user + guide messages, returns kid-facing content" do
    allow(client).to receive(:chat).and_return(llm_response("Resposta calma do Guia."))
    result = described_class.call(learner: learner, mission: mission, user_content: "Por que 23 min?", client: client)

    expect(result).to be_success
    expect(result.data[:user_message].content).to eq("Por que 23 min?")
    expect(result.data[:guide_message].content).to eq("Resposta calma do Guia.")
    expect(result.data[:remaining_messages]).to eq(4)
    expect(result.data[:closed]).to be(false)
    expect(result.data[:guide_message].tokens_in).to eq(50)
    expect(result.data[:guide_message].tokens_out).to eq(30)
  end

  it "detects [SAFETY_FLAG] prefix, sets flag + strips marker from kid-facing content" do
    allow(client).to receive(:chat).and_return(llm_response("[SAFETY_FLAG][bullying] Isso é mais forte que eu, fala com um adulto hoje."))

    result = described_class.call(learner: learner, mission: mission, user_content: "tem um menino me batendo", client: client)

    convo = result.data[:conversation].reload
    expect(convo.flagged).to be(true)
    expect(convo.flag_reasons).to eq([ "bullying" ])
    expect(result.data[:guide_message].content).to eq("Isso é mais forte que eu, fala com um adulto hoje.")
    expect(result.data[:guide_message].flagged).to be(true)
  end

  it "blocks call before LLM when quota is exhausted" do
    convo = create(:academy_guide_conversation, learner_id: learner.id, mission: mission, started_at: 1.hour.ago)
    5.times { create(:academy_guide_message, conversation: convo, role: :user) }

    expect(client).not_to receive(:chat)
    result = described_class.call(learner: learner, mission: mission, user_content: "oi", client: client)
    expect(result).not_to be_success
    expect(result.error).to eq(:quota_exhausted)
  end

  it "marks conversation closed after the 5th user message" do
    allow(client).to receive(:chat).and_return(llm_response("ok"))
    5.times { described_class.call(learner: learner, mission: mission, user_content: "uma pergunta", client: client) }
    convo = Academy::GuideConversation.last
    expect(convo.closed_at).to be_present
  end

  it "rolls back persistence on Client::Error and does not consume a quota slot" do
    allow(client).to receive(:chat).and_raise(Academy::Llm::Client::Error, "boom")

    expect {
      described_class.call(learner: learner, mission: mission, user_content: "olá", client: client)
    }.not_to change(Academy::GuideMessage, :count)

    quota = Academy::Guide::QuotaCheck.call(learner: learner, mission: mission)
    expect(quota.data[:remaining_messages]).to eq(5)
  end

  it "fails fast when LLM key is missing" do
    allow(Academy).to receive(:configured?).and_return(false)
    result = described_class.call(learner: learner, mission: mission, user_content: "oi", client: client)
    expect(result.error).to eq(:no_llm_key)
  end

  it "fails on empty content" do
    result = described_class.call(learner: learner, mission: mission, user_content: "   ", client: client)
    expect(result.error).to eq(:empty_content)
  end
end
