# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Llm::Client do
  let(:config) do
    Academy::Config.new(
      openrouter_api_key: "x" * 20, openrouter_base_url: "https://example.test/v1",
      model: "fake/m", temperature: 0.5, max_tokens: 100, referer: nil, app_title: nil,
      judge_model: nil, judge_temperature: 0.0, judge_max_tokens: 100, judge_reasoning_effort: "minimal"
    )
  end
  let(:client) { described_class.new(config: config) }

  let(:success_body) do
    {
      choices: [ { message: { content: '{"ok":true}' }, finish_reason: "stop" } ],
      usage: { total_tokens: 7 }, model: "fake/m"
    }.to_json
  end

  def stub_http(*responses)
    http = instance_double(Net::HTTP)
    seq = responses.dup
    allow(Net::HTTP).to receive(:start).and_yield(http).and_wrap_original do |_orig, *_args, &block|
      block.call(http)
    end
    allow(http).to receive(:request) do
      r = seq.shift
      r.is_a?(Exception) ? (raise r) : r
    end
  end

  def fake_response(code, body = "{}")
    res = instance_double(Net::HTTPResponse, code: code, body: body)
    allow(res).to receive(:is_a?).with(any_args).and_return(false)
    allow(res).to receive(:is_a?).with(Net::HTTPSuccess).and_return(code == "200")
    res
  end

  context "transient 5xx" do
    it "retries once on 502 and returns the second response" do
      allow(client).to receive(:sleep)
      stub_http(fake_response("502", "{}"), fake_response("200", success_body))
      result = client.chat(messages: [ { role: "user", content: "hi" } ])
      expect(result[:content]).to eq('{"ok":true}')
    end

    it "does not retry on 401" do
      allow(client).to receive(:sleep)
      stub_http(fake_response("401", '{"error":"bad key"}'))
      expect {
        client.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(Academy::Llm::Client::Error, /401/)
    end

    it "gives up after one retry — raises on the second 503" do
      allow(client).to receive(:sleep)
      stub_http(fake_response("503", "{}"), fake_response("503", "{}"))
      expect {
        client.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(Academy::Llm::Client::Error, /503/)
    end
  end

  context "Net::OpenTimeout" do
    it "retries once on open_timeout then succeeds" do
      allow(client).to receive(:sleep)
      stub_http(Net::OpenTimeout.new("connect failed"), fake_response("200", success_body))
      result = client.chat(messages: [ { role: "user", content: "hi" } ])
      expect(result[:content]).to eq('{"ok":true}')
    end

    it "gives up after one open_timeout retry" do
      allow(client).to receive(:sleep)
      stub_http(Net::OpenTimeout.new("once"), Net::OpenTimeout.new("twice"))
      expect {
        client.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(Academy::Llm::Client::Error, /open_timeout/)
    end
  end
end
