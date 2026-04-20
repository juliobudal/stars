namespace :tasks do
  desc "Instantiates daily missions for all children based on global tasks"
  task daily_reset: :environment do
    puts "Starting daily reset for #{Date.current}..."
    Tasks::DailyResetService.new.call
    puts "Daily reset complete!"
  end
end
