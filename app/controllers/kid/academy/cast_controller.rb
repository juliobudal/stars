# frozen_string_literal: true

# Cast gallery — lists the 5 sub-voices that narrate the lens stages.
# Each card shows the voice's tagline + how many lens visits the learner
# has already had with that voice, so the kid feels the "elenco" growing.
class Kid::Academy::CastController < Kid::Academy::BaseController
  def index
    @voices = ::Academy::Lens::Voices.all
    @visits_by_voice = visits_by_voice
    @visited_voice_keys = @visits_by_voice.select { |_, n| n.positive? }.keys.to_set
  end

  private

  def visits_by_voice
    counts = ::Academy::LearnerLensVisit
               .where(learner_id: current_learner.id)
               .where.not(closed_at: nil)
               .group(:lens_type).count

    ::Academy::Lens::Voices.all.to_h do |voice|
      total = ::Academy::Lens::Voices::LENS_TO_VOICE
                .select { |_lens, vkey| vkey == voice.key }
                .sum { |lens, _| counts[lens.to_s].to_i }
      [ voice.key, total ]
    end
  end
end
