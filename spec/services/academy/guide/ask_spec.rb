# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::Ask do
  let(:learner) { Academy::Learner.new(id: 5, display_name: "Kid", age_band: "kid") }
  let(:lesson) { create(:academy_lesson) }
  let(:fake_client) do
    instance_double(Academy::Llm::Client, chat: { content: "Pensa assim: ...", raw: {}, tokens: 10 })
  end

  before { allow(Academy).to receive(:configured?).and_return(true) }

  it "persists the user message and the guide reply" do
    result = described_class.call(learner: learner, lesson: lesson, user_content: "por quê?", client: fake_client)
    expect(result).to be_success
    expect(result.data[:user_message].content).to eq("por quê?")
    expect(result.data[:guide_message]).to be_guide
  end

  it "fails when the LLM is not configured" do
    allow(Academy).to receive(:configured?).and_return(false)
    result = described_class.call(learner: learner, lesson: lesson, user_content: "x", client: fake_client)
    expect(result.error).to eq(:no_llm_key)
  end

  it "rejects empty input" do
    result = described_class.call(learner: learner, lesson: lesson, user_content: "  ", client: fake_client)
    expect(result.error).to eq(:empty_content)
  end

  it "enforces the daily question quota" do
    described_class::DAILY_QUESTION_LIMIT.times do |i|
      described_class.call(learner: learner, lesson: lesson, user_content: "q#{i}", client: fake_client)
    end
    result = described_class.call(learner: learner, lesson: lesson, user_content: "uma a mais", client: fake_client)
    expect(result.error).to eq(:quota_exceeded)
  end

  it "flags safety-marked replies" do
    flag_client = instance_double(
      Academy::Llm::Client,
      chat: { content: "[SAFETY_FLAG][bullying]\nConta pra um adulto.", raw: {}, tokens: 5 }
    )
    result = described_class.call(learner: learner, lesson: lesson, user_content: "me xingaram", client: flag_client)
    expect(result.data[:conversation].reload.flagged).to be(true)
    expect(result.data[:guide_message].content).not_to include("SAFETY_FLAG")
  end
end
