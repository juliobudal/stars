# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observability::ErrorSubscriber do
  subject(:subscriber) { described_class.new }

  let(:error) { StandardError.new("boom") }

  def report(context)
    subscriber.report(error, handled: true, severity: :error, context: context, source: "test")
  end

  it "emits one tagged, JSON-tailed log line for a simple context" do
    expect(Rails.logger).to receive(:error).with(/\[Observability::ErrorSubscriber\].*"error_report"/)
    report(profile_id: 1, source: "x")
  end

  it "never raises when the context is circular (the bug that masked errors as SystemStackError)" do
    circular = {}
    circular[:self] = circular

    expect { report(circular) }.not_to raise_error
  end

  it "flattens non-scalar context values instead of serializing them deeply" do
    logged = nil
    allow(Rails.logger).to receive(:error) { |line| logged = line }

    report(record: Object.new, count: 3)

    expect(logged).to include('"count":3')
    expect(logged).to be_present
  end
end
