# frozen_string_literal: true

class Parent::Academy::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @children = current_family.profiles.where(role: :child).order(:name)
    @subjects = ::Academy::Subject.active.order(:position, :id).to_a

    return if @children.empty?

    @selected_kid = pick_kid(@children)
    load_kid_dashboard(@selected_kid)
  end

  # Side-by-side cross-child comparison.
  def compare
    @children = current_family.profiles.where(role: :child).order(:name)

    @rows = @children.map do |child|
      {
        child: child,
        completed: ::Academy::MissionProgress.where(learner_id: child.id, status: [ :completed, :mastered ]).count,
        cards: ::Academy::DiscoveryCard.where(learner_id: child.id).count
      }
    end
  end

  private

  def pick_kid(children)
    return children.first if params[:kid_id].blank?

    children.find { |c| c.id.to_s == params[:kid_id].to_s } || children.first
  end

  def load_kid_dashboard(kid)
    # v5: 1:1 mission↔concept — go through the mission FK directly.
    @concepts_by_category = ::Academy::Concept
                              .joins(missions: :discovery_cards)
                              .where(academy_discovery_cards: { learner_id: kid.id })
                              .distinct
                              .pluck(:category, :slug, :name)
                              .group_by { |row| row[0] }
                              .transform_values { |rows| rows.map { |_, slug, name| { slug: slug, name: name } } }

    @recent_cards = ::Academy::DiscoveryCard
                      .for_learner(kid.id)
                      .includes(mission: :subject)
                      .limit(5)

    @secret_unlocks = ::Academy::SecretUnlock
                        .for_learner(kid.id)
                        .includes(:secret)
                        .order(unlocked_at: :desc)
                        .limit(8)

    @weekly_tokens = ::Academy::Message
                       .joins(session: :mission_progress)
                       .where(academy_mission_progresses: { learner_id: kid.id })
                       .where(role: ::Academy::Message.roles[:guide])
                       .where("academy_messages.created_at >= ?", 7.days.ago)
                       .where.not(tokens: nil)
                       .sum(:tokens)
  end
end
