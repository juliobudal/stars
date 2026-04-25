class Ui::FamilySelector::Component < ApplicationComponent
  def initialize(profile:)
    @profile = profile
    @family = profile.family
  end

  private

  def initial
    @family.name.to_s.strip.first&.upcase || "?"
  end
end
