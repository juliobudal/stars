class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "LittleStars <no-reply@localhost>")
  layout "mailer"
end
