class Parent::ApprovalsController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  def index
    @profile_tasks = Approvals::PendingTasksQuery.new(family: current_profile.family).call
    @redemptions = Approvals::PendingRedemptionsQuery.new(family: current_profile.family).call
  end

  def approve
    @profile_task = ProfileTask.includes(:profile, :global_task).joins(:profile).where(profiles: { family_id: current_profile.family_id }).find(params[:id])
    result = Tasks::ApproveService.call(@profile_task)
    respond_after(result, success_msg: "Tarefa aprovada com sucesso!", fail_msg: "Não foi possível aprovar a tarefa.")
  end

  def reject
    @profile_task = ProfileTask.includes(:profile, :global_task).joins(:profile).where(profiles: { family_id: current_profile.family_id }).find(params[:id])
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
