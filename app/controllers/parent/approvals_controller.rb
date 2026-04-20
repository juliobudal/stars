class Parent::ApprovalsController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  def index
    @profile_tasks = current_profile.family.profile_tasks.awaiting_approval
                                    .joins(:profile)
                                    .order("profiles.name ASC, profile_tasks.created_at DESC")
    
    @redemptions = Redemption.pending.joins(:profile)
                                  .where(profiles: { family_id: current_profile.family_id })
                                  .select("redemptions.*, profiles.name as profile_name")
                                  .order(created_at: :desc)
  end

  def approve
    @profile_task = current_profile.family.profile_tasks.find(params[:id])
    
    if Tasks::ApproveService.new(@profile_task).call
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: "Tarefa aprovada com sucesso!" }
        format.turbo_stream
      end
    else
      redirect_to parent_approvals_path, alert: "Não foi possível aprovar a tarefa."
    end
  end

  def approve_redemption
    @redemption = Redemption.find(params[:id])
    # Ensure family scope
    return unless current_profile.family.profiles.include?(@redemption.profile)

    if @redemption.update(status: :approved)
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: "Resgate aprovado!" }
        format.turbo_stream { render :approve_redemption }
      end
    else
      redirect_to parent_approvals_path, alert: "Erro ao aprovar resgate."
    end
  end

  def reject_redemption
    @redemption = Redemption.find(params[:id])
    return unless current_profile.family.profiles.include?(@redemption.profile)

    ActiveRecord::Base.transaction do
      @redemption.update!(status: :rejected)
      # Refund points
      @redemption.profile.increment!(:points, @redemption.points)
      @redemption.profile.activity_logs.create!(
        log_type: :adjust,
        title: "Resgate Recusado (Reembolso): #{@redemption.title}",
        points: @redemption.points
      )
    end

    respond_to do |format|
      format.html { redirect_to parent_approvals_path, notice: "Resgate rejeitado e pontos devolvidos." }
      format.turbo_stream { render :reject_redemption }
    end
  rescue => e
    redirect_to parent_approvals_path, alert: "Erro: #{e.message}"
  end

  def reject
    @profile_task = current_profile.family.profile_tasks.find(params[:id])
    
    if Tasks::RejectService.new(@profile_task).call
      respond_to do |format|
        format.html { redirect_to parent_approvals_path, notice: "Tarefa rejeitada." }
        format.turbo_stream
      end
    else
      redirect_to parent_approvals_path, alert: "Não foi possível rejeitar a tarefa."
    end
  end
end
