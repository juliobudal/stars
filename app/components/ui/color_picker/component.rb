class Ui::ColorPicker::Component < ApplicationComponent
  DEFAULT_OPTIONS = %w[peach rose mint sky lilac coral].freeze

  def initialize(form:, field:, options: DEFAULT_OPTIONS, label: nil, input_data: {})
    @form = form
    @field = field
    @options = options
    @label = label
    @input_data = input_data
  end

  attr_reader :form, :field, :options, :label, :input_data
end
