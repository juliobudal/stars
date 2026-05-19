# frozen_string_literal: true

# Records LLM-as-judge verdict alongside the generated lens payload so we
# can audit pedagogical quality offline, tune the rubric over time, and
# drive future re-generation of weak rows.
#
# `judge_verdict` is intentionally a free string (PASS/REVISE/FAIL, plus
# "skipped" if the judge was disabled or unreachable at generation time)
# rather than a check-constrained enum — we expect the rubric to evolve.
class AddJudgeColsToAcademyLensCache < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_lens_cache, :judge_verdict, :string
    add_column :academy_lens_cache, :judge_overall_score, :integer
    add_column :academy_lens_cache, :judge_revision_cycles, :integer, default: 0, null: false
    add_column :academy_lens_cache, :judge_critique, :text

    add_index :academy_lens_cache, :judge_verdict,
              name: :idx_academy_lens_cache_judge_verdict,
              where: "judge_verdict IS NOT NULL"
  end
end
