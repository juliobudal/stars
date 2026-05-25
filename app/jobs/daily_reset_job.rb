class DailyResetJob < ApplicationJob
  queue_as :default

  def perform
    Family.find_each do |family|
      result = Tasks::DailyResetService.new(family: family).call
      Rails.logger.info("[DailyResetJob] family_id=#{family.id} created=#{result.data&.dig(:created) || 0}")
    end
  end
end
