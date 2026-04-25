class Ui::PinModal::Component < ApplicationComponent
  def initialize(profile:, error: nil)
    @profile = profile
    @error = error
  end

  attr_reader :profile, :error
end
