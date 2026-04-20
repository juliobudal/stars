ActivityLog.destroy_all
ProfileTask.destroy_all
Reward.destroy_all
GlobalTask.destroy_all
Profile.destroy_all
Family.destroy_all

puts "Creating Demo Family..."
family = Family.create!(name: "Familia Demo")

puts "Creating Profiles..."
parent1 = family.profiles.create!(name: "Pai", role: :parent, points: 0)
parent2 = family.profiles.create!(name: "Mãe", role: :parent, points: 0)
child1 = family.profiles.create!(name: "Filho 1", role: :child, points: 0)
child2 = family.profiles.create!(name: "Filho 2", role: :child, points: 0)

puts "Creating Global Tasks..."
task1 = family.global_tasks.create!(title: "Arrumar a cama", category: :casa, points: 10, frequency: :daily)
task2 = family.global_tasks.create!(title: "Fazer lição de casa", category: :escola, points: 20, frequency: :daily)
task3 = family.global_tasks.create!(title: "Lavar a louça", category: :casa, points: 15, frequency: :daily)
task4 = family.global_tasks.create!(title: "Comer vegetais", category: :rotina, points: 5, frequency: :daily)
task5 = family.global_tasks.create!(title: "Ajudar na faxina", category: :casa, points: 30, frequency: :weekly)

puts "Creating Profile Tasks..."
# Assign tasks to children
task1.profile_tasks.create!(profile: child1, status: :pending, assigned_date: Date.current)
task2.profile_tasks.create!(profile: child1, status: :pending, assigned_date: Date.current)
task2.profile_tasks.create!(profile: child2, status: :pending, assigned_date: Date.current)

puts "Creating Rewards..."
family.rewards.create!(title: "Sorvete", cost: 50, icon: "gift")
family.rewards.create!(title: "Cinema", cost: 150, icon: "ticket")
family.rewards.create!(title: "Jogo Novo", cost: 500, icon: "puzzle-piece")

puts "Seed complete!"
