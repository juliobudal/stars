# week_start: integer column — 0 = Sunday, 1 = Monday (matches Ruby Date#wday convention).
# Default is 1 (Monday). Used to determine the start of the week for stats and day grouping.
# == Schema Information
#
# Table name: families
#
#  id                     :bigint           not null, primary key
#  allow_negative         :boolean          default(FALSE)
#  auto_approve_threshold :integer
#  decay_enabled          :boolean          default(FALSE)
#  locale                 :string           default("pt-BR")
#  max_debt               :integer          default(100), not null
#  name                   :string
#  require_photo          :boolean          default(FALSE)
#  timezone               :string           default("America/Sao_Paulo")
#  week_start             :integer          default(1)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :profile_tasks, through: :profiles
  has_many :profile_invitations, dependent: :destroy
end
