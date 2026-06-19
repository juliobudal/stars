class Ui::ProfilePicker::Component < ApplicationComponent
  def initialize(profiles:, selected: nil, pin_error: nil)
    @profiles = profiles
    @selected = selected
    @pin_error = pin_error
  end

  attr_reader :profiles, :selected, :pin_error
end
