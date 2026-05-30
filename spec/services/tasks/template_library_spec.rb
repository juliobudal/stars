# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::TemplateLibrary do
  # Guards Parent::GlobalTasksController#add_from_template, which uses create!:
  # every curated template MUST build a valid GlobalTask, otherwise a one-click
  # "add from library" would 500 in production.
  let(:family) { create(:family) }

  it "every template builds a valid GlobalTask" do
    described_class.all.each do |tpl|
      attrs = described_class.attributes_for(tpl[:key])
      task = GlobalTask.new(attrs.merge(family: family))
      expect(task).to be_valid, "template #{tpl[:key].inspect}: #{task.errors.full_messages.join(', ')}"
    end
  end

  it "attributes_for returns nil for unknown/blank keys" do
    expect(described_class.attributes_for("nope")).to be_nil
    expect(described_class.attributes_for("")).to be_nil
  end
end
