ActivityLog.delete_all
ProfileTask.delete_all
Redemption.delete_all
Reward.delete_all
GlobalTask.delete_all
Profile.delete_all
Family.delete_all

ActiveRecord::Base.strict_loading_by_default = false

puts "Creating Demo Family..."
family = Family.create!(name: "Estrelas Incríveis")

puts "Creating Profiles..."
parent1 = Profile.create!(family: family, name: "Mamãe", role: :parent, avatar: "faceParent", color: "rose")
parent2 = Profile.create!(family: family, name: "Papai", role: :parent, avatar: "faceParent", color: "sky")

child1 = Profile.create!(family: family, name: "Lila", role: :child, avatar: "faceFox", color: "peach", points: 340)
child2 = Profile.create!(family: family, name: "Theo", role: :child, avatar: "faceHero", color: "sky", points: 180)
child3 = Profile.create!(family: family, name: "Zoe", role: :child, avatar: "facePrincess", color: "rose", points: 520)

puts "Creating Global Tasks..."
task1 = GlobalTask.create!(family: family, title: "Arrumar a cama", category: :casa, points: 20, frequency: :daily, icon: "bed")
task2 = GlobalTask.create!(family: family, title: "Escovar os dentes", category: :rotina, points: 10, frequency: :daily, icon: "brush")
task3 = GlobalTask.create!(family: family, title: "Fazer a lição de casa", category: :escola, points: 50, frequency: :daily, icon: "book")
task4 = GlobalTask.create!(family: family, title: "Lavar a louça", category: :casa, points: 40, frequency: :daily, icon: "dish")
task5 = GlobalTask.create!(family: family, title: "Ler um livro", category: :escola, points: 30, frequency: :weekly, icon: "bookOpen")
task6 = GlobalTask.create!(family: family, title: "Dar comida ao pet", category: :rotina, points: 15, frequency: :daily, icon: "paw")

puts "Creating Profile Tasks..."
# Use direct creation to avoid traversing associations on records with strict loading
# Lila's tasks
ProfileTask.create!(profile: child1, global_task: task1, status: :pending, assigned_date: Date.current)
ProfileTask.create!(profile: child1, global_task: task2, status: :pending, assigned_date: Date.current)
ProfileTask.create!(profile: child1, global_task: task3, status: :awaiting_approval, assigned_date: Date.current)
ProfileTask.create!(profile: child1, global_task: task6, status: :pending, assigned_date: Date.current)

# Theo's tasks
ProfileTask.create!(profile: child2, global_task: task1, status: :awaiting_approval, assigned_date: Date.current)
ProfileTask.create!(profile: child2, global_task: task4, status: :pending, assigned_date: Date.current)

# Zoe's tasks
ProfileTask.create!(profile: child3, global_task: task5, status: :pending, assigned_date: Date.current)

puts "Creating Rewards..."
Reward.create!(family: family, title: "Sorvete de chocolate", cost: 80, icon: "iceCream", category: :doce)
Reward.create!(family: family, title: "1h de Video Game", cost: 150, icon: "gamepad", category: :tela)
Reward.create!(family: family, title: "Passeio ao parque", cost: 250, icon: "ferris", category: :passeio)
Reward.create!(family: family, title: "LEGO novo", cost: 600, icon: "blocks", category: :brinquedo)
Reward.create!(family: family, title: "Escolher filme", cost: 50, icon: "film", category: :experiencia)

puts "Creating Mission Assignments..."
# task3 (lição) → only Lila and Zoe
GlobalTaskAssignment.create!(global_task: task3, profile: child1)
GlobalTaskAssignment.create!(global_task: task3, profile: child3)
# task4 (louça) → only Theo
GlobalTaskAssignment.create!(global_task: task4, profile: child2)

puts "Seed complete! 🌟"
