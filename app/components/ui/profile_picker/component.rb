class Ui::ProfilePicker::Component < ApplicationComponent
  def initialize(profiles:, selected: nil)
    @profiles = profiles
    @selected = selected
  end

  attr_reader :profiles, :selected
end
