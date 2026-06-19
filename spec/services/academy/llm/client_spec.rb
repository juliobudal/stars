# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Llm::Client do
  subject(:client) { described_class.new(config: config) }

  let(:config) do
    Academy::Config.new(
      openrouter_api_key: "test-key-1234567890",
      openrouter_base_url: "https://openrouter.ai/api/v1",
      model: "test/model",
      temperature: 0.7,
      max_tokens: 1000,
      referer: "https://littlestars.app",
      app_title: "Test"
    )
  end

  let(:messages) { [ { role: "user", content: "oi" } ] }

  # Build a real Net::HTTPResponse subclass so `is_a?(Net::HTTPSuccess)` and
  # `#code` behave like production; only the body is stubbed (the socket is
  # never read in a unit test).
  def http_response(klass, code, body)
    res = klass.new("1.1", code, "msg")
    allow(res).to receive(:body).and_return(body)
    res
  end

  def http_ok(body)
    http_response(Net::HTTPOK, "200", body)
  end

  def completion_body(content:, finish: "stop")
    {
      "choices" => [ { "message" => { "content" => content }, "finish_reason" => finish } ],
      "usage" => { "prompt_tokens" => 5, "completion_tokens" => 7, "total_tokens" => 12 }
    }.to_json
  end

  it "raises when the API key is missing" do
    bare = described_class.new(config: Academy::Config.new(openrouter_api_key: ""))
    expect { bare.chat(messages: messages) }.to raise_error(described_class::Error, /not set/)
  end

  it "returns parsed content, usage, and finish_reason on success" do
    allow(Net::HTTP).to receive(:start).and_return(http_ok(completion_body(content: "Pensa nisso.")))

    result = client.chat(messages: messages)

    expect(result[:content]).to eq("Pensa nisso.")
    expect(result[:tokens]).to eq(12)
    expect(result[:finish_reason]).to eq("stop")
  end

  it "raises Error on a non-2xx response" do
    allow(Net::HTTP).to receive(:start)
      .and_return(http_response(Net::HTTPBadRequest, "400", %({"error":"boom"})))

    expect { client.chat(messages: messages) }.to raise_error(described_class::Error, /HTTP 400/)
  end

  it "raises Error on an empty completion" do
    allow(Net::HTTP).to receive(:start).and_return(http_ok(completion_body(content: "   ")))

    expect { client.chat(messages: messages) }.to raise_error(described_class::Error, /Empty completion/)
  end

  it "raises Error on invalid JSON" do
    allow(Net::HTTP).to receive(:start).and_return(http_ok("definitely not json"))

    expect { client.chat(messages: messages) }.to raise_error(described_class::Error, /Invalid JSON/)
  end

  it "retries once on a 503 then succeeds" do
    allow(client).to receive(:sleep) # don't actually back off in tests
    allow(Net::HTTP).to receive(:start).and_return(
      http_response(Net::HTTPServiceUnavailable, "503", "down"),
      http_ok(completion_body(content: "recovered"))
    )

    result = client.chat(messages: messages)

    expect(result[:content]).to eq("recovered")
    expect(Net::HTTP).to have_received(:start).twice
  end

  it "does NOT retry on a read timeout and surfaces it as Error" do
    calls = 0
    allow(Net::HTTP).to receive(:start) { calls += 1; raise Net::ReadTimeout }

    expect { client.chat(messages: messages) }.to raise_error(described_class::Error, /read_timeout/)
    expect(calls).to eq(1)
  end

  it "retries once on an open timeout then succeeds" do
    allow(client).to receive(:sleep)
    seq = [ -> { raise Net::OpenTimeout }, -> { http_ok(completion_body(content: "back")) } ]
    allow(Net::HTTP).to receive(:start) { seq.shift.call }

    result = client.chat(messages: messages)

    expect(result[:content]).to eq("back")
  end
end
