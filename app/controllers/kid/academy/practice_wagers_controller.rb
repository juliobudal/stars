# frozen_string_literal: true

class Kid::Academy::PracticeWagersController < Kid::Academy::BaseController
  def update
    wager = ::Academy::PracticeWager
              .for_learner(current_learner.id)
              .find(params[:id])

    result = ::Academy::Wagers::Settle.call(
      wager: wager,
      actual_count: params[:actual_count],
      note: params[:note]
    )

    if result.success?
      redirect_to kid_academy_subjects_path,
                  notice: "Aposta registrada — o Guia comenta na próxima."
    else
      redirect_to kid_academy_subjects_path, alert: result.error
    end
  end
end
