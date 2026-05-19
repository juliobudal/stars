# frozen_string_literal: true

# Adds the structured "concept brief" used by Academy::Lens generators.
#
# Why these 3 columns:
#   * the_essence       — the single sentence the lens should pivot around.
#                         Replaces LLM-inferred "what is the concept" with a
#                         curator-locked north star. All 8 lens types align.
#   * common_confusion  — the typical 7-12yo misread of the concept. Used to
#                         (a) prime the LLM to write distractors that match
#                         real-world wrong answers in micro_check, (b) give
#                         the judge a known confusion to penalize against.
#   * forbidden_terms   — array of words/phrases that, for THIS concept, are
#                         tempting but pedagogically wrong (e.g. "prazer" for
#                         dopamina). Generators::Base will inject these into
#                         the prompt AND into its tone-violation guard.
#
# All three are nullable: concepts without curation fall back to `definition`
# and ship a lens just as before. This migration is additive only.
class AddBriefFieldsToAcademyConcepts < ActiveRecord::Migration[8.1]
  def change
    change_table :academy_concepts, bulk: true do |t|
      t.text   :the_essence,
               comment: "Curator's one-sentence north star — what every lens must point to"
      t.text   :common_confusion,
               comment: "Typical 7-12yo misread of this concept — feeds micro_check distractors"
      t.text   :forbidden_terms, array: true, default: [], null: false,
               comment: "Words this concept must never use (e.g. 'prazer' for dopamina)"
    end
  end
end
