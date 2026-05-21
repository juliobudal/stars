# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Illustrations::Client do
  let(:config) do
    Academy::Config.new(
      openrouter_api_key: "x" * 20,
      openrouter_base_url: "https://example.test/v1",
      model: "fake/m", temperature: 0.5, max_tokens: 100,
      referer: nil, app_title: nil,
      image_model: "fake/img",
      image_size: "1K",
      image_aspect_ratio: "1:1"
    )
  end
  let(:client) { described_class.new(config: config) }

  # 1×1 transparent PNG, base64 — minimum valid PNG payload.
  let(:tiny_png_b64) do
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
  end
  let(:tiny_png_bytes) { Base64.decode64(tiny_png_b64) }

  let(:success_body) do
    {
      choices: [ { message: { images: [ { image_url: { url: "data:image/png;base64,#{tiny_png_b64}" } } ] } } ],
      usage: { prompt_tokens: 10, completion_tokens: 1290, total_tokens: 1300 }
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

  describe "success path" do
    it "returns decoded image bytes and metadata" do
      stub_http(fake_response("200", success_body))
      result = client.generate(prompt: "test scene")

      expect(result[:mime]).to eq("image/png")
      expect(result[:bytes]).to eq(tiny_png_bytes)
      expect(result[:model]).to eq("fake/img")
      expect(result[:raw]).to be_a(Hash)
    end

    it "allows model override per call" do
      stub_http(fake_response("200", success_body))
      result = client.generate(prompt: "x", model: "other/model")
      expect(result[:model]).to eq("other/model")
    end
  end

  describe "missing API key" do
    let(:config) do
      Academy::Config.new(
        openrouter_api_key: "", openrouter_base_url: "https://example.test/v1",
        model: nil, temperature: nil, max_tokens: nil, referer: nil, app_title: nil,
        image_model: "fake/img", image_size: "1K", image_aspect_ratio: "1:1"
      )
    end

    it "raises before issuing the HTTP request" do
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /OPENROUTER_API_KEY/)
    end
  end

  describe "transient 5xx" do
    it "retries on 503 and returns the second response" do
      allow(client).to receive(:sleep)
      stub_http(fake_response("503"), fake_response("200", success_body))
      result = client.generate(prompt: "x")
      expect(result[:bytes]).to eq(tiny_png_bytes)
    end

    it "gives up after retries and raises" do
      allow(client).to receive(:sleep)
      stub_http(fake_response("503"), fake_response("503"), fake_response("503"))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /503/)
    end
  end

  describe "timeouts" do
    it "retries on Net::ReadTimeout and recovers" do
      allow(client).to receive(:sleep)
      stub_http(Net::ReadTimeout.new("read"), fake_response("200", success_body))
      result = client.generate(prompt: "x")
      expect(result[:bytes]).to eq(tiny_png_bytes)
    end

    it "raises Error after persistent timeouts" do
      allow(client).to receive(:sleep)
      stub_http(Net::OpenTimeout.new("open"), Net::OpenTimeout.new("open"), Net::OpenTimeout.new("open"))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /timeout/)
    end
  end

  describe "malformed response" do
    it "raises when images array is missing" do
      body = { choices: [ { message: { content: "just text" } } ] }.to_json
      stub_http(fake_response("200", body))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /missing images/)
    end

    it "raises when data URL prefix is malformed" do
      body = { choices: [ { message: { images: [ { image_url: { url: "not-a-data-url" } } ] } } ] }.to_json
      stub_http(fake_response("200", body))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /Malformed data URL/)
    end

    it "raises when decoded bytes are empty" do
      body = { choices: [ { message: { images: [ { image_url: { url: "data:image/png;base64," } } ] } } ] }.to_json
      stub_http(fake_response("200", body))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /empty/)
    end

    it "raises on non-200 HTTP" do
      stub_http(fake_response("400", '{"error":"bad request"}'))
      expect { client.generate(prompt: "x") }.to raise_error(described_class::Error, /HTTP 400/)
    end
  end
end
