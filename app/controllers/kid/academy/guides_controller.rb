# frozen_string_literal: true

# "O Guia" chat surface — five-message daily Q&A for the active mission.
# Talks to Academy::Guide::{QuotaCheck, FindOrStartConversation, Ask}.
# Hidden entirely when OPENROUTER_API_KEY is missing — this controller is
# the only Academy surface that requires the LLM at runtime, so the guard
# lives here (not in BaseController) and the rest of Academy keeps working.
class Kid::Academy::GuidesController < Kid::Academy::BaseController
  before_action :require_academy_configured!
  before_action :load_subject_and_mission

  # GET /kid/academy/subjects/:subject_id/missions/:mission_id/guide
  def show
    quota = ::Academy::Guide::QuotaCheck.call(learner: current_learner, mission: @mission).data
    @conversation = quota[:existing_conversation]
    @remaining = quota[:remaining_messages]
    @session_state = quota[:session_state]
    @messages = @conversation ? visible_messages(@conversation) : []
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
      @remaining = result.data[:remaining_messages]
      @session_state = @conversation.closed? ? :closed_today : :open
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
    when :quota_exhausted then "Você já usou as 5 perguntas de hoje. Volta amanhã!"
    when :llm_error then "O Guia está descansando. Tenta de novo em alguns minutos."
    else "Não consegui falar com O Guia agora."
    end
  end
end
