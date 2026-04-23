class ProfileInvitation < ApplicationRecord
  belongs_to :family
  belongs_to :invited_by, class_name: "Profile", optional: true

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  scope :active, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def accept!(name:, password:)
    ActiveRecord::Base.transaction do
      profile = Profile.new(
        role: :parent,
        name: name,
        email: email,
        password: password,
        confirmed_at: Time.current,
        family: family
      )
      profile.save!
      update!(accepted_at: Time.current)
      profile
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= Time.current + 7.days
  end
end
