# frozen_string_literal: true

module Academy
  # Cached cross-area rank for a learner. Recomputed after every mission
# == Schema Information
#
# Table name: academy_learner_ranks
#
#  id                                                                                :bigint           not null, primary key
#  rank(0=aprendiz, 1=explorador, 2=construtor, 3=estrategista, 4=criador, 5=mentor) :integer          default("aprendiz"), not null
#  created_at                                                                        :datetime         not null
#  updated_at                                                                        :datetime         not null
#  learner_id                                                                        :bigint           not null
#
# Indexes
#
#  idx_academy_learner_rank_unique  (learner_id) UNIQUE
#
  # finalize + challenge report. Cheap to read on the home header.
  class LearnerRank < ApplicationRecord
    self.table_name = "academy_learner_ranks"

    enum :rank, {
      aprendiz:     0,
      explorador:   1,
      construtor:   2,
      estrategista: 3,
      criador:      4,
      mentor:       5
    }, default: :aprendiz

    LABELS = {
      "aprendiz"     => "Aprendiz",
      "explorador"   => "Explorador",
      "construtor"   => "Construtor",
      "estrategista" => "Estrategista",
      "criador"      => "Criador",
      "mentor"       => "Mentor"
    }.freeze

    ICONS = {
      "aprendiz"     => "sparkle",
      "explorador"   => "compass",
      "construtor"   => "tools",
      "estrategista" => "puzzle",
      "criador"      => "magic",
      "mentor"       => "trophy"
    }.freeze

    validates :learner_id, presence: true, uniqueness: true

    def label = LABELS.fetch(rank.to_s, "Aprendiz")
    def icon  = ICONS.fetch(rank.to_s, "sparkle")
  end
end
