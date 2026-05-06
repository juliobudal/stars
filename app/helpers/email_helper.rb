# Email-specific design tokens. Email clients (Outlook, Gmail, Apple Mail)
# do not reliably support CSS custom properties or external stylesheets, so
# the values must be inlined as literal hex. This module centralizes the hex
# so the templates do not duplicate the brand palette and so the in-email
# values stay aligned with theme.css when the design system shifts.
module EmailHelper
  EMAIL_TOKENS = {
    primary:    "#58CC02",
    star:       "#FFD93D",
    text:       "#1A2A4A",
    text_muted: "#777777",
    surface:    "#FFFFFF",
    bg:         "#F7F7F7",
    hairline:   "#E5E5E5"
  }.freeze

  EMAIL_FONT_STACK = "'Nunito', 'Helvetica Neue', Arial, sans-serif"

  def email_token(name)
    EMAIL_TOKENS.fetch(name)
  end

  def email_font_stack
    EMAIL_FONT_STACK
  end
end
