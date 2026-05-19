# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Catalog do
  it "exposes exactly the 8 v5 lens types" do
    expect(described_class.types).to contain_exactly(
      :scientific, :narrative, :ethical, :statistical,
      :engineering, :historical, :first_person, :analogy_bridge
    )
  end

  it "marks analogy_bridge and ethical as closure-eligible" do
    expect(described_class.closure_types).to contain_exactly(:analogy_bridge, :ethical)
  end

  it "rejects unknown types" do
    expect { described_class.fetch(:imaginary) }.to raise_error(ArgumentError)
  end

  describe "entry shape" do
    described_class::TYPES.each_pair do |type, entry|
      it "pins ui_primitive, template, schema, version for #{type}" do
        expect(entry.ui_primitive).to be_a(Symbol)
        expect(entry.prompt_template).to end_with(".md.erb")
        expect(entry.schema_file).to end_with(".json")
        expect(entry.template_version).to match(/\A#{type}\.v\d+\z/)
      end
    end
  end

  it "resolves prompt_path under the lens module root" do
    path = described_class.prompt_path(:scientific)
    expect(path.to_s).to end_with("app/services/academy/lens/prompts/scientific.md.erb")
  end

  it "resolves schema_path under the lens module root" do
    path = described_class.schema_path(:narrative)
    expect(path.to_s).to end_with("app/services/academy/lens/schemas/narrative.json")
  end
end
