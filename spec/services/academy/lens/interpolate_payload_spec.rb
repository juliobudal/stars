# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::InterpolatePayload do
  let(:learner) { Academy::Learner.new(id: 1, display_name: "Lara", age_band: "kid") }

  it "replaces learner_name in top-level strings" do
    result = described_class.render(
      payload: { "headline" => "Olá, {{learner_name}}!" }, learner: learner
    )
    expect(result["headline"]).to eq("Olá, Lara!")
  end

  it "replaces tokens deep inside nested hashes and arrays" do
    payload = {
      "headline" => "Pergunta para {{learner_name}}",
      "scenes" => [
        { "text" => "{{learner_name}} comeu um doce" },
        { "choices" => [ "Ir com {{sibling_or_friend}}", "Esperar" ] }
      ]
    }
    result = described_class.render(payload: payload, learner: learner)
    expect(result["headline"]).to eq("Pergunta para Lara")
    expect(result["scenes"][0]["text"]).to eq("Lara comeu um doce")
    expect(result["scenes"][1]["choices"]).to eq([ "Ir com um amigo", "Esperar" ])
  end

  it "leaves non-string values alone (numbers, booleans, nil)" do
    payload = { "count" => 3, "ok" => true, "missing" => nil }
    expect(described_class.render(payload: payload, learner: learner)).to eq(payload)
  end

  it "tolerates whitespace inside the braces" do
    result = described_class.render(
      payload: { "t" => "{{  learner_name  }} venceu" }, learner: learner
    )
    expect(result["t"]).to eq("Lara venceu")
  end

  it "does NOT mutate the original payload (cache safety)" do
    payload = { "headline" => "Oi {{learner_name}}" }
    described_class.render(payload: payload, learner: learner)
    expect(payload["headline"]).to eq("Oi {{learner_name}}")
  end

  it "falls back to 'você' when learner has no display_name" do
    nameless = Academy::Learner.new(id: 2, display_name: nil, age_band: "kid")
    result = described_class.render(payload: { "h" => "Oi {{learner_name}}" }, learner: nameless)
    expect(result["h"]).to eq("Oi você")
  end

  it "returns nil unchanged" do
    expect(described_class.render(payload: nil, learner: learner)).to be_nil
  end

  it "leaves unknown tokens verbatim" do
    result = described_class.render(payload: { "t" => "Oi {{unknown_token}}" }, learner: learner)
    expect(result["t"]).to eq("Oi {{unknown_token}}")
  end
end
