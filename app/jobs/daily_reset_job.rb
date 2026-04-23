class DailyResetJob < ApplicationJob
  queue_as :default

  def perform
    Family.find_each do |family|
      count = Tasks::DailyResetService.new(family: family).call
      Rails.logger.info("[DailyResetJob] family_id=#{family.id} created=#{count}")
    end
  end
end
