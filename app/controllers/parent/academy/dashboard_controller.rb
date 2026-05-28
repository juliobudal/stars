# frozen_string_literal: true

# Read-only parent view of each child's Academy progress per trail.
class Parent::Academy::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @children = current_family.profiles.where(role: :child).order(:name).to_a
    @trails = ::Academy::Trail.active.ordered.to_a

    @progress_by_child = @children.index_with do |child|
      ::Academy::Trail.progress_for(child.id, trails: @trails)
    end
  end
end
