# frozen_string_literal: true

# Lightning Round — 60-90s retrieval round across 5 fading concepts.
# Single-page wizard: server-rendered, all 5 questions in one form.
# Kid submits; controller scores and updates LearnerConcept.last_seen_at
# (and bumps level on success).
class Kid::Academy::LightningController < Kid::Academy::BaseController
  def show
    result = ::Academy::Pills::BuildLightningRound.call(learner: current_learner)
    unless result.success?
      flash[:notice] = lightning_unavailable_copy(result.error)
      return redirect_to(kid_root_path)
    end

    @rounds = result.data[:rounds]
    session[:lightning_rounds] = @rounds.map { |r|
      r.slice(:concept_id, :correct_index, :concept_name)
    }
    session[:lightning_started_at] = Time.current.to_i
  end

  def answer
    rounds = Array(session[:lightning_rounds]).map(&:symbolize_keys)
    started = session[:lightning_started_at].to_i
    allowed_keys = rounds.each_index.map { |i| "q#{i}" }
    submissions = params.fetch(:answer, {}).permit(*allowed_keys).to_h
    correct = 0

    rounds.each_with_index do |r, i|
      chosen = submissions["q#{i}"].to_i
      if chosen == r[:correct_index]
        correct += 1
        bump_learner_concept(r[:concept_id], hit: true)
      else
        bump_learner_concept(r[:concept_id], hit: false)
      end
    end

    @correct = correct
    @total   = rounds.size
    @elapsed = (Time.current.to_i - started).clamp(0, 600)
    @tier    = result_tier(@correct, @total)

    ::Academy::LightningRoundRun.create!(
      learner_id: current_learner.id,
      total_questions: @total, correct_count: @correct,
      elapsed_seconds: @elapsed, tier: @tier.to_s,
      concept_ids: rounds.map { |r| r[:concept_id] }
    )
    @is_champion = ::Academy::LightningRoundRun.champion?(current_learner.id)

    session.delete(:lightning_rounds)
    session.delete(:lightning_started_at)
    render :result
  end

  private

  def bump_learner_concept(concept_id, hit:)
    lc = ::Academy::LearnerConcept.find_by(
      learner_id: current_learner.id, concept_id: concept_id
    )
    return unless lc

    if hit && lc.level < 3
      lc.update!(level: lc.level + 1, last_seen_at: Time.current)
    else
      lc.update!(last_seen_at: Time.current)
    end
  end

  def result_tier(correct, total)
    ratio = correct.to_f / total
    return :perfect if ratio >= 1.0
    return :strong  if ratio >= 0.6
    :gentle
  end

  def lightning_unavailable_copy(error)
    case error
    when :not_enough_concepts
      "Tomou poucas pílulas ainda — volta quando tiver mais aulas!"
    when :no_micro_checks
      "Sem perguntas prontas pra Lightning Round agora."
    else
      "Lightning Round indisponível agora."
    end
  end
end
