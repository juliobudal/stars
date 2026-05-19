# frozen_string_literal: true

module Academy
  module Digests
    # Weekly composer job. Recurring config in `config/recurring.yml`.
    # Iterates all parent/child pairs with activity in the prior week and
    # composes (or skips) the digest for each.
    class WeeklyJob < ApplicationJob
      queue_as :default

      def perform(week_starting: Date.current.beginning_of_week(:monday))
        Family.find_each do |family|
          parents = family.profiles.where(role: :parent)
          children = family.profiles.where(role: :child)
          next if parents.empty? || children.empty?

          children.find_each do |child|
            parents.find_each do |parent|
              Compose.call(
                learner_id: child.id,
                parent_id: parent.id,
                week_starting: week_starting
              )
            end
          end
        end
      end
    end
  end
end
