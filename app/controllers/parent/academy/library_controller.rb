# frozen_string_literal: true

# Parent curation surface: browse every active pílula in the catalog with
# filters by area, source (author), and framework. Read-only — curriculum
# is seed-driven. The parent can use this to know what their kid is
# learning, who said it, and what didactic method O Guia uses.
class Parent::Academy::LibraryController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @subjects = ::Academy::Subject.active.order(:position)
    @selected_subject  = params[:area].presence
    @selected_source   = params[:source].presence
    @selected_framework = params[:framework].presence

    missions = ::Academy::Mission.active.includes(:subject).order("academy_subjects.position", :order_in_subject)
    missions = missions.joins(:subject).where(academy_subjects: { slug: @selected_subject }) if @selected_subject
    missions = missions.where(source: @selected_source) if @selected_source
    missions = missions.where(framework: @selected_framework) if @selected_framework
    @missions = missions

    @grouped = @missions.group_by(&:subject)

    @available_sources    = ::Academy::Mission.where(active: true).where.not(source: nil)
                                              .distinct.reorder(:source).pluck(:source)
    @available_frameworks = ::Academy::Mission.where(active: true).where.not(framework: nil)
                                              .distinct.reorder(:framework).pluck(:framework)
  end
end
