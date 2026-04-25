module PaletteHelper
  def palette_for(profile)
    profile&.color.presence || "primary"
  end
end
