# == Schema Information
#
# Table name: profile_invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  expires_at    :datetime         not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  family_id     :bigint           not null
#  invited_by_id :bigint
#
# Indexes
#
#  index_profile_invitations_on_family_id  (family_id)
#  index_profile_invitations_on_token      (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id) ON DELETE => cascade
#  fk_rails_...  (invited_by_id => profiles.id) ON DELETE => nullify
#
class ProfileInvitation < ApplicationRecord
  belongs_to :family
  belongs_to :invited_by, class_name: "Profile", optional: true

  # The raw token is never persisted — only its SHA256 digest (token_digest).
  # The plaintext is exposed via `raw_token` right after creation so the mailer
  # can build the acceptance URL, then it's gone. Look invitations up with
  # `.find_by_token(raw)`, never by a stored plaintext token.
  attr_reader :raw_token

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :token_digest, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  scope :active, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  # Hashes a raw token the same way it was stored, for lookup.
  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  # Finds an invitation by its raw (emailed) token via the stored digest.
  def self.find_by_token(token)
    return nil if token.blank?
    find_by(token_digest: digest(token))
  end

  # Marks the invitation as accepted and returns the family.
  # Profile creation now happens through the regular onboarding flow
  # (see Auth::AcceptInvitation service + InvitationsController).
  def accept!
    update!(accepted_at: Time.current)
    family
  end

  private

  def generate_token
    return if token_digest.present?
    @raw_token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@raw_token)
  end

  def set_expires_at
    self.expires_at ||= Time.current + 7.days
  end
end
