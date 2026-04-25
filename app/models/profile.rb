# == Schema Information
#
# Table name: profiles
#
#  id              :bigint           not null, primary key
#  avatar          :string
#  color           :string
#  email           :citext
#  name            :string
#  pin_digest      :string
#  points          :integer          default(0)
#  role            :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  family_id       :bigint           not null
#
# Indexes
#
#  index_profiles_on_family_id     (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
class Profile < ApplicationRecord
  PIN_FORMAT = /\A\d{4}\z/

  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :sent_invitations, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :nullify

  attr_accessor :pin

  enum :role, { child: 0, parent: 1 }, default: :child

  before_validation { email&.downcase! }
  before_save :hash_pin, if: -> { pin.present? }

  after_update_commit :broadcast_points, if: :saved_change_to_points?

  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }, unless: -> { family&.allow_negative? }
  validates :color, inclusion: { in: %w[peach rose mint sky lilac coral primary], allow_blank: true }
  validates :email, allow_blank: true, format: URI::MailTo::EMAIL_REGEXP
  validates :pin, format: { with: PIN_FORMAT, message: "deve ter 4 dígitos numéricos" }, if: -> { pin.present? }
  validates :pin_digest, presence: true, on: :create, unless: -> { pin.present? }

  def authenticate_pin(candidate)
    return false if pin_digest.blank?
    BCrypt::Password.new(pin_digest) == candidate.to_s
  end

  def full_name
    name
  end

  def avatar_url(*_args)
    avatar.presence
  end

  private

  def hash_pin
    self.pin_digest = BCrypt::Password.create(pin)
    self.pin = nil
  end

  def broadcast_points
    broadcast_update_to self, "notifications", target: "profile_points_#{id}", html: points.to_s
  end
end
