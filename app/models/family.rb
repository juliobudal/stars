# week_start: integer column — 0 = Sunday, 1 = Monday (matches Ruby Date#wday convention).
# Default is 1 (Monday). Used to determine the start of the week for stats and day grouping.
# == Schema Information
#
# Table name: families
#
#  id                     :bigint           not null, primary key
#  allow_negative         :boolean          default(FALSE)
#  auto_approve_threshold :integer
#  day_start_hour         :integer          default(0), not null
#  decay_enabled          :boolean          default(FALSE)
#  email                  :citext
#  last_reset_on          :date
#  locale                 :string           default("pt-BR")
#  max_debt               :integer          default(100), not null
#  name                   :string
#  password_digest        :string
#  require_photo          :boolean          default(FALSE)
#  timezone               :string           default("America/Sao_Paulo")
#  week_start             :integer          default(1)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_families_on_email  (email) UNIQUE
#
class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :profile_tasks, through: :profiles
  has_many :redemptions, through: :profiles
  has_many :profile_invitations, dependent: :destroy

  has_secure_password

  before_validation { email&.downcase! }

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: URI::MailTo::EMAIL_REGEXP
  validates :password, length: { minimum: 12 }, allow_nil: true
  validates :day_start_hour,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt&.last(10)
  end

  after_create :seed_default_categories

  # "Today" for this family: the local date with the daily rollover anchored at
  # `day_start_hour` (e.g. with start_hour 6, 05:30 local still counts as
  # yesterday). Single source of truth for task scheduling — used by
  # Tasks::DailyResetService and Tasks::SetAssignments so both agree on the day.
  def current_date(now = Time.current)
    local = now.in_time_zone(timezone || "UTC")
    local.hour < day_start_hour.to_i ? (local - 1.day).to_date : local.to_date
  end

  private

  def seed_default_categories
    result = Categories::SeedDefaultsService.call(self)
    return if result.success?

    Rails.logger.error("[Family##{id}] category seeding failed: #{result.error}")
    raise ActiveRecord::Rollback
  end
end
