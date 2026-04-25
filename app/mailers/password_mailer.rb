class PasswordMailer < ApplicationMailer
  def reset(family, token)
    @family = family
    @token = token
    mail(to: @family.email, subject: "Redefinição de senha — LittleStars")
  end
end
