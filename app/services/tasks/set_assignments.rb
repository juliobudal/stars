# frozen_string_literal: true

module Tasks
  # Reconciles which children a GlobalTask is assigned to, given the full
  # desired set of child profile ids (as the assignment matrix submits a whole
  # row at once).
  #
  # Assignment semantics mirror Tasks::DailyResetService: a task with ZERO
  # GlobalTaskAssignment rows is implicitly assigned to ALL children. So a
  # desired set covering every child is stored as "no rows" — keeping future
  # children auto-included. A mission cannot be assigned to nobody; an empty
  # desired set (with children present) fails with :needs_at_least_one so the
  # caller can revert the toggle.
  #
  # Side effects keep today consistent without waiting for the next daily reset:
  #   * newly-assigned children get today's slot (if the task fires today)
  #   * un-assigned children lose their still-pending slot for the period
  class SetAssignments < ApplicationService
    def initialize(global_task:, profile_ids:, date: nil)
      @global_task = global_task
      @desired = Array(profile_ids).map(&:to_i).reject(&:zero?).uniq
      @date = date
    end

    # Toggle a single child on/off a task while preserving implicit-"all"
    # semantics. Starts from the task's current effective member set, adds or
    # removes the one child, then reconciles through #call — keeping the
    # implicit-all rule owned by this service instead of re-derived in
    # controllers.
    #
    # Note: removing one child from an implicit-"all" task necessarily
    # materializes an explicit set for the remaining children (there is no
    # "all except X" representation), so future-added children stop being
    # auto-included until the task is reset back to "all".
    def self.toggle(global_task:, profile_id:, assigned:, date: nil)
      pid = profile_id.to_i
      all_ids = Profile.child.where(family_id: global_task.family_id).pluck(:id)
      explicit = GlobalTaskAssignment.where(global_task_id: global_task.id).pluck(:profile_id)
      effective = explicit.any? ? explicit : all_ids
      desired = assigned ? (effective | [ pid ]) : (effective - [ pid ])
      call(global_task: global_task, profile_ids: desired, date: date)
    end

    def call
      all_child_ids = child_ids
      desired = @desired & all_child_ids

      return fail_with(:needs_at_least_one) if desired.empty? && all_child_ids.any?

      previous = effective_ids(all_child_ids)

      ActiveRecord::Base.transaction do
        if desired.sort == all_child_ids.sort
          assignments.delete_all # collapse to implicit "all"
        else
          reconcile(desired)
        end
      end

      current = effective_ids(all_child_ids)
      apply_slot_effects(previous: previous, current: current)
      ok(assigned_ids: current)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::SetAssignments] global_task_id=#{@global_task.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    # Direct queries (not association traversal) so the strict_loading host
    # GlobalTask passed in doesn't raise in development.
    def assignments
      GlobalTaskAssignment.where(global_task_id: @global_task.id)
    end

    def child_ids
      Profile.child.where(family_id: @global_task.family_id).pluck(:id)
    end

    # `pluck` always issues a fresh query, so this reflects committed state
    # both before and after the reconcile transaction.
    def effective_ids(all_child_ids)
      explicit = assignments.pluck(:profile_id)
      explicit.any? ? explicit.sort : all_child_ids.sort
    end

    def reconcile(desired)
      existing = assignments.pluck(:profile_id)
      to_remove = existing - desired
      to_add = desired - existing

      assignments.where(profile_id: to_remove).delete_all if to_remove.any?
      to_add.each { |pid| GlobalTaskAssignment.create!(global_task_id: @global_task.id, profile_id: pid) }
    end

    def apply_slot_effects(previous:, current:)
      date = @date || today
      added = current - previous
      removed = previous - current

      if @global_task.active? && @global_task.applicable_on?(date)
        Profile.where(id: added).each do |child|
          @global_task.materialize_slot_for(child, date)
        end
      end

      if removed.any?
        ProfileTask
          .where(global_task: @global_task, profile_id: removed)
          .in_period_for(@global_task, date)
          .pending
          .update_all(status: ProfileTask.statuses[:expired], updated_at: Time.current)
      end
    end

    def today
      Family.find(@global_task.family_id).current_date
    end
  end
end
