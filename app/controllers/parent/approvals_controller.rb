class Parent::ApprovalsController < ApplicationController
  include Authenticatable
  layout "parent"
  before_action :require_parent!

  def index
    @profile_tasks = Approvals::PendingTasksQuery.new(family: current_profile.family).call
    @redemptions = Approvals::PendingRedemptionsQuery.new(family: current_profile.family).call
  end

  def bulk_approve
    perform_bulk(service: Tasks::ApproveService, success_msg: ->(n) { "#{n} tarefa(s) aprovada(s)." })
  end

  def bulk_reject
    perform_bulk(service: Tasks::RejectService, success_msg: ->(n) { "#{n} tarefa(s) rejeitada(s)." })
  end

  def approve
    @profile_task = family_profile_tasks.find(params[:id])
    override = params[:points_override].presence&.to_i
    result = Tasks::ApproveService.call(@profile_task, points_override: override)
    respond_after(result, success_msg: "Tarefa aprovada com sucesso!", fail_msg: "Não foi possível aprovar a tarefa.")
  end

  def reject
    @profile_task = family_profile_tasks.find(params[:id])
    result = Tasks::RejectService.call(@profile_task)
    respond_after(result, success_msg: "Tarefa rejeitada.", fail_msg: "Não foi possível rejeitar a tarefa.")
  end

  def approve_redemption
    @redemption = family_redemptions.find(params[:id])
    result = Rewards::ApproveRedemptionService.call(@redemption)

    if result.success?
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: "Resgate aprovado!" }
        format.turbo_stream { render :approve_redemption }
      end
    else
      redirect_to parent_approvals_path, alert: result.error || "Erro ao aprovar resgate."
    end
  end

  def reject_redemption
    @redemption = family_redemptions.find(params[:id])
    result = Rewards::RejectRedemptionService.call(@redemption)

    if result.success?
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: "Resgate rejeitado e pontos devolvidos." }
        format.turbo_stream { render :reject_redemption }
      end
    else
      redirect_to parent_approvals_path, alert: result.error || "Erro ao rejeitar resgate."
    end
  end

  private

  def perform_bulk(service:, success_msg:)
    ids = Array(params[:approval_ids]).reject(&:blank?)
    if ids.empty?
      redirect_to parent_approvals_path, alert: "Nenhuma tarefa selecionada."
      return
    end

    processed_ids = ids.filter_map do |id|
      task = family_profile_tasks.find_by(id: id)
      next unless task
      result = service.call(task)
      id if result.success?
    end

    respond_to do |format|
      format.html { redirect_to parent_approvals_path, notice: success_msg.call(processed_ids.size) }
      format.turbo_stream do
        render turbo_stream: processed_ids.map { |id| turbo_stream.remove("profile_task_#{id}") }
      end
    end
  end

  def family_profile_tasks
    ProfileTask.includes(:profile, :global_task).joins(:profile).where(profiles: { family_id: current_profile.family_id })
  end

  def family_redemptions
    Redemption.includes(:profile).joins(:profile).where(profiles: { family_id: current_profile.family_id })
  end

  def respond_after(result, success_msg:, fail_msg:)
    if result.success?
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: success_msg }
        format.turbo_stream
      end
    else
      redirect_to parent_approvals_path, alert: result.error || fail_msg
    end
  end
end
