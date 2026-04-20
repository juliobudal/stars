class DailyResetJob < ApplicationJob
  queue_as :default

  def perform
    Tasks::DailyResetService.new.call
  end
end
