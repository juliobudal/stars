# frozen_string_literal: true

module Academy
  # Created by Secrets::EvaluateForLearner the first time a secret's rule
  # == Schema Information
  #
  # Table name: academy_secret_unlocks
  #
  #  id          :bigint           not null, primary key
  #  seen        :boolean          default(FALSE), not null
  #  unlocked_at :datetime         not null
  #  created_at  :datetime         not null
  #  updated_at  :datetime         not null
  #  learner_id  :bigint           not null
  #  secret_id   :bigint           not null
  #
  # Indexes
  #
  #  idx_academy_secret_unlocks_unique          (learner_id,secret_id) UNIQUE
  #  index_academy_secret_unlocks_on_secret_id  (secret_id)
  #
  # Foreign Keys
  #
  #  fk_rails_...  (secret_id => academy_secrets.id)
  #
  # is satisfied. `seen=false` triggers the celebratory banner on the home.
  class SecretUnlock < ApplicationRecord
    self.table_name = "academy_secret_unlocks"

    belongs_to :secret, class_name: "Academy::Secret"

    validates :learner_id, presence: true
    validates :learner_id, uniqueness: { scope: :secret_id }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :unseen, -> { where(seen: false) }
  end
end
