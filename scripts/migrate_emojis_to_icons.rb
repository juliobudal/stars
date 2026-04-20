# scripts/migrate_emojis_to_icons.rb

mapping = {
  '🍦' => 'gift',
  '🍿' => 'ticket',
  '🎮' => 'puzzle-piece',
  '🏠' => 'home',
  '🏫' => 'academic-cap',
  '⏰' => 'clock',
  '⭐' => 'star',
  '📝' => 'clipboard-document-text',
  '⚽' => 'cake',
  '📱' => 'device-phone-mobile',
  '📖' => 'book-open',
  '🧹' => 'home-modern',
  '🎨' => 'paint-brush',
  '🥣' => 'sparkles'
}

puts "Starting emoji migration..."

updated_rewards = 0
Reward.find_each do |reward|
  if mapping.key?(reward.icon)
    old = reward.icon
    reward.update!(icon: mapping[old])
    puts "Reward: #{reward.title} (#{old} -> #{reward.icon})"
    updated_rewards += 1
  end
end

updated_tasks = 0
GlobalTask.find_each do |task|
  # If tasks used icons in the icon field if it exists
  if task.respond_to?(:icon) && mapping.key?(task.icon)
     old = task.icon
     task.update!(icon: mapping[old])
     puts "Task: #{task.title} (#{old} -> #{task.icon})"
     updated_tasks += 1
  end
end

puts "Migration complete!"
puts "Updated Rewards: #{updated_rewards}"
puts "Updated Tasks: #{updated_tasks}"
