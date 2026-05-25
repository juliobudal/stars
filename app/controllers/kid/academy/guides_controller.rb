# frozen_string_literal: true

# "O Guia" chat surface — open Q&A scoped to the active mission.
# Talks to Academy::Guide::{FindOrStartConversation, Ask}.
# Hidden entirely when OPENROUTER_API_KEY is missing — this controller is
# the only Academy surface that requires the LLM at runtime, so the guard
# lives here (not in BaseController) and the rest of Academy keeps working.
class Kid::Academy::GuidesController < Kid::Academy::BaseController
  # Defensive cap against retry storms / scripted abuse hitting the LLM.
  rate_limit to: 10, within: 1.minute, only: :create

  before_action :require_academy_configured!
  before_action :load_subject_and_mission

  # GET /kid/academy/subjects/:subject_id/missions/:mission_id/guide
  def show
    @conversation = ::Academy::Guide::FindOrStartConversation.call(
      learner: current_learner, mission: @mission
    ).data
    @messages = visible_messages(@conversation)
  end

  # POST /kid/academy/subjects/:subject_id/missions/:mission_id/guide
  def create
    result = ::Academy::Guide::Ask.call(
      learner: current_learner,
      mission: @mission,
      user_content: params[:content].to_s
    )

    if result.success?
      @conversation = result.data[:conversation]
      @messages = visible_messages(@conversation)
      @just_sent = [ result.data[:user_message], result.data[:guide_message] ]
      render :show
    else
      redirect_to kid_academy_subject_mission_guide_path(@subject, @mission),
                  alert: error_message(result.error)
    end
  end

  private

  def require_academy_configured!
    return if ::Academy.configured?

    redirect_to kid_root_path, alert: "O Guia está indisponível agora."
  end

  def load_subject_and_mission
    @subject = ::Academy::Subject.active.find_by!(slug: params[:subject_id])
    @mission = @subject.missions.active.find_by!(slug: params[:mission_id])
  end

  def visible_messages(conversation)
    conversation.messages.where(role: [
      ::Academy::GuideMessage.roles[:user],
      ::Academy::GuideMessage.roles[:guide]
    ]).order(:created_at)
  end

  def error_message(error)
    case error
    when :empty_content then "Escreve sua pergunta antes de enviar."
    when :llm_error then "O Guia está descansando. Tenta de novo em alguns minutos."
    else "Não consegui falar com O Guia agora."
    end
  end
end
