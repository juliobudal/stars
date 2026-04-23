class Profile < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :sent_invitations, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :nullify

  has_secure_password validations: false

  enum :role, { child: 0, parent: 1 }, default: :child

  before_validation { email&.downcase! }

  after_update_commit :broadcast_points, if: :saved_change_to_points?

  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }, unless: -> { family&.allow_negative? }
  validates :color, inclusion: { in: %w[peach rose mint sky lilac coral primary], allow_blank: true }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: URI::MailTo::EMAIL_REGEXP,
                    if: :parent?
  validates :password, length: { minimum: 12 }, allow_nil: true, if: :parent?
  validates :password, presence: true, on: :create, if: :parent?

  def full_name
    name
  end

  def avatar_url(*args)
    avatar.presence
  end

  private

  def broadcast_points
    broadcast_update_to self, "notifications", target: "profile_points_#{id}", html: points.to_s
  end
end
