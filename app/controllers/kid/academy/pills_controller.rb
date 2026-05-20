# frozen_string_literal: true

# "Pílula do Dia" — the lowest-friction Academy surface (60-90s).
# Served at /kid/academy/pill (show) and via the kid home card.
class Kid::Academy::PillsController < Kid::Academy::BaseController
  PAGE_SIZE = 12

  def index
    @page  = [ params[:page].to_i, 1 ].max
    scope  = ::Academy::PillView.for_learner(current_learner.id).recent
              .includes(lens_cache: :concept)
    @total = scope.count
    @pills = scope.limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE)
    @has_more = @total > @page * PAGE_SIZE
  end

  def show
    result = ::Academy::Pills::PickDailyForLearner.call(learner: current_learner)
    unless result.success?
      flash[:notice] = "Sem pílula nova por hoje. Volta amanhã!"
      return redirect_to(kid_root_path)
    end

    @pill_view  = result.data[:pill_view]
    @lens_cache = result.data[:lens_cache]
    @concept    = @lens_cache.concept
    @payload    = ::Academy::Lens::InterpolatePayload.render(
      payload: @lens_cache.payload, learner: current_learner
    )
    @lens_type  = @lens_cache.lens_type
    @primitive  = lens_primitive(@lens_type)
    @voice      = ::Academy::Lens::Voices.for_lens(@lens_type)
    @action_label = ::Academy::Lens::Catalog.kid_action_label(@lens_type)

    @pill_view.mark_viewed!
  end

  def share
    pill = ::Academy::PillView.for_learner(current_learner.id).find(params[:id])
    pill.mark_shared!
    # The parent side polls `Academy::PillView.where(shared_with_parent: true,
    # learner_id: family_kid_ids).order(updated_at: :desc)` — no Turbo broadcast
    # yet, that lands when the parent home gets a 'shared pills' widget.
    redirect_to(kid_root_path, notice: "Show! Compartilhei com o pai/mãe.")
  end

  private

  # Mirrors lens_stage.html.erb. Kept inline so this controller stands alone
  # without forcing a partial extraction.
  def lens_primitive(lens_type)
    case lens_type.to_sym
    when :scientific, :statistical    then "predict"
    when :narrative                   then "narrative"
    when :ethical                     then "compare"
    when :analogy_bridge, :historical then "pattern_hunt"
    when :first_person                then "embodied"
    when :engineering                 then "engineering"
    end
  end
end
