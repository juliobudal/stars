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

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  scope :active, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  # Marks the invitation as accepted and returns the family.
  # Profile creation now happens through the regular onboarding flow
  # (see Auth::AcceptInvitation service + InvitationsController).
  def accept!
    update!(accepted_at: Time.current)
    family
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= Time.current + 7.days
  end
end
