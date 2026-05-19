# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::InterpolatePayload do
  let(:learner) { Academy::Learner.new(id: 1, display_name: "Joana", age_band: "kid") }

  it "still interpolates the legacy `{{learner_name}}` syntax" do
    result = described_class.render(payload: { "h" => "Oi {{learner_name}}!" }, learner: learner)
    expect(result["h"]).to eq("Oi Joana!")
  end

  it "interpolates the new `[[learner_name]]` syntax" do
    result = described_class.render(payload: { "h" => "Oi [[learner_name]]!" }, learner: learner)
    expect(result["h"]).to eq("Oi Joana!")
  end

  it "interpolates a mixed-syntax payload" do
    result = described_class.render(
      payload: { "h" => "{{learner_name}} e [[sibling_or_friend]] foram ao parque" },
      learner: learner
    )
    expect(result["h"]).to eq("Joana e um amigo foram ao parque")
  end
end
