class PasswordMailer < ApplicationMailer
  def reset(profile, token)
    @profile = profile
    @token = token
    mail(to: @profile.email, subject: "Redefinição de senha — LittleStars")
  end
end
