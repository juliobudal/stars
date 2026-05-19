# frozen_string_literal: true

# Academy v4 — Replace numeric rank presentation with a narrative title.
# The numeric tier column stays for analytics; the kid UI reads title_slug.
#
# Vocabulary:
#   curious      # default (egg)
#   observer     # first concept sighted
#   explorer     # 5 missions across ≥2 subjects
#   cartographer # at least 1 transfer detected
#   naturalist   # ≥40 concepts, 5 subjects touched
#   mentor       # rare, long-term
class AddTitleSlugToAcademyLearnerRanks < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_learner_ranks, :title_slug, :string,
               comment: "curious | observer | explorer | cartographer | naturalist | mentor"

    add_index :academy_learner_ranks, :title_slug,
              name: "idx_academy_learner_ranks_title_slug"
  end
end
