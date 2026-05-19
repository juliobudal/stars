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

  # Side-by-side cross-child comparison. Same dataset as #index but
  # collapsed to a comparable shape (radar scores + completion counts).
  def compare
    @children = current_family.profiles.where(role: :child).order(:name)
    @skills = ::Academy::Skill.ordered.to_a

    learner_ids = @children.map(&:id)
    skills_by_learner = ::Academy::LearnerSkill
                          .where(learner_id: learner_ids)
                          .group_by(&:learner_id)

    @rows = @children.map do |child|
      indexed = (skills_by_learner[child.id] || []).index_by(&:skill_id)
      {
        child: child,
        rank: ::Academy::LearnerRank.find_by(learner_id: child.id),
        scores: @skills.map { |s| indexed[s.id]&.score.to_i },
        completed: ::Academy::MissionProgress.where(learner_id: child.id, status: [ :completed, :mastered ]).count,
        cards: ::Academy::DiscoveryCard.where(learner_id: child.id).count
      }
    end

    @skill_max = (@rows.flat_map { |r| r[:scores] }.max || 0).clamp(20, Float::INFINITY).to_i
  end

  private

  def pick_kid(children)
    return children.first if params[:kid_id].blank?

    children.find { |c| c.id.to_s == params[:kid_id].to_s } || children.first
  end

  def load_kid_dashboard(kid)
    @rank_record = ::Academy::LearnerRank.find_by(learner_id: kid.id)

    @skills = ::Academy::Skill.ordered.to_a
    learner_skills = ::Academy::LearnerSkill.where(learner_id: kid.id).index_by(&:skill_id)
    @skill_scores = @skills.map { |s| learner_skills[s.id]&.score.to_i }
    @skill_max = (@skill_scores.max || 0).clamp(20, Float::INFINITY).to_i

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
