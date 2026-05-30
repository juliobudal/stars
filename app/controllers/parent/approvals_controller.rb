class Parent::ApprovalsController < ApplicationController
  include Authenticatable
  layout "parent"
  before_action :require_parent!

  def index
    @profile_tasks = Approvals::PendingTasksQuery.new(family: current_profile.family).call
    @redemptions = Approvals::PendingRedemptionsQuery.new(family: current_profile.family).call
  end

  def bulk_approve
    perform_bulk(service: Tasks::ApproveService, scope: family_profile_tasks, dom_prefix: "profile_task_",
                 empty_alert: "Nenhuma tarefa selecionada.", success_msg: ->(n) { "#{n} tarefa(s) aprovada(s)." })
  end

  def bulk_reject
    perform_bulk(service: Tasks::RejectService, scope: family_profile_tasks, dom_prefix: "profile_task_",
                 empty_alert: "Nenhuma tarefa selecionada.", success_msg: ->(n) { "#{n} tarefa(s) rejeitada(s)." })
  end

  def bulk_approve_redemptions
    perform_bulk(service: Rewards::ApproveRedemptionService, scope: family_redemptions, dom_prefix: "redemption_",
                 empty_alert: "Nenhum resgate selecionado.", success_msg: ->(n) { "#{n} resgate(s) marcado(s) como entregue(s)." })
  end

  def bulk_reject_redemptions
    perform_bulk(service: Rewards::RejectRedemptionService, scope: family_redemptions, dom_prefix: "redemption_",
                 empty_alert: "Nenhum resgate selecionado.", success_msg: ->(n) { "#{n} resgate(s) rejeitado(s) e estrelas devolvidas." })
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

  # Single bulk handler for tasks and redemptions. `scope` is the family-scoped
  # relation to look records up in; `dom_prefix` is the row id prefix used by
  # the turbo_stream removals (bulk.turbo_stream.erb). The bulk bar submits via
  # Turbo (bulk_select_controller#submit), so the turbo_stream branch runs in
  # place and the active tab is preserved.
  def perform_bulk(service:, scope:, dom_prefix:, empty_alert:, success_msg:)
    ids = Array(params[:approval_ids]).reject(&:blank?)
    if ids.empty?
      redirect_to parent_approvals_path, alert: empty_alert
      return
    end

    @processed_ids = ids.filter_map do |id|
      record = scope.find_by(id: id)
      next unless record
      id if service.call(record).success?
    end
    @dom_prefix = dom_prefix
    @bulk_message = success_msg.call(@processed_ids.size)

    # Surface partial failures (record vanished, lost a race, service refused)
    # instead of silently reporting only the successes.
    failed = ids.size - @processed_ids.size
    if failed.positive?
      @bulk_message += failed == 1 ? " 1 item não pôde ser processado." : " #{failed} itens não puderam ser processados."
    end

    respond_to do |format|
      format.html { redirect_to parent_approvals_path, notice: @bulk_message }
      format.turbo_stream { render :bulk }
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
