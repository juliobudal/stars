# Idempotent: skip wipe + seed if any Family already exists, unless SEED_FORCE=1.
if Family.exists? && ENV["SEED_FORCE"] != "1"
  puts "↪ Seed skipped: #{Family.count} family/families already present. Use SEED_FORCE=1 to re-seed."
  exit
end

if ENV["SEED_FORCE"] == "1"
  puts "⚠ SEED_FORCE=1 — wiping all data..."
  [ ActivityLog, Redemption, ProfileTask, GlobalTaskAssignment, Reward, Category, GlobalTask, Profile, ProfileInvitation, Family ].each(&:delete_all)
end

ActiveRecord::Base.strict_loading_by_default = false

puts "Creating Família Budal..."
family = Family.create!(
  name: "Família Budal",
  email: "familia@budal.dev",
  password: "supersecret1234"
)

puts "Creating Profiles..."
mae = Profile.create!(family: family, name: "Mamãe", role: :parent,
                      color: "rose", email: "mae@budal.dev", pin: "1111")
pai = Profile.create!(family: family, name: "Papai", role: :parent,
                      color: "sky", email: "pai@budal.dev", pin: "2222")

theo  = Profile.create!(family: family, name: "Theo",  role: :child,
                        color: "sky",   points: 50, pin: "1111")
lis   = Profile.create!(family: family, name: "Lis",   role: :child,
                        color: "rose",  points: 50, pin: "2222")
laura = Profile.create!(family: family, name: "Laura", role: :child,
                        color: "lilac", points: 50, pin: "3333")

kids = [ theo, lis, laura ]

puts "Creating Global Tasks..."
# Star economy starter set:
#   daily   5–20 ⭐ (small/repeatable rotina + casa)
#   weekly  25–50 ⭐ (effort)
#   once   80–150 ⭐ (aspirational/milestone)
missions = [
  # Rotina diária
  { title: "Escovar os dentes (manhã)",      points: 5,   frequency: :daily,  category: :rotina, icon: "tooth-01" },
  { title: "Escovar os dentes (noite)",      points: 5,   frequency: :daily,  category: :rotina, icon: "tooth-01" },
  { title: "Arrumar a cama",                 points: 10,  frequency: :daily,  category: :casa,   icon: "bed-01" },
  { title: "Tomar banho sem reclamar",       points: 10,  frequency: :daily,  category: :saude,  icon: "shower" },
  { title: "Guardar os brinquedos",          points: 10,  frequency: :daily,  category: :casa,   icon: "toys" },
  { title: "Ajudar a pôr a mesa",            points: 10,  frequency: :daily,  category: :casa,   icon: "dish" },
  { title: "Comer toda a verdura no almoço", points: 15,  frequency: :daily,  category: :saude,  icon: "broccoli" },
  { title: "Ler 15 minutos",                 points: 15,  frequency: :daily,  category: :escola, icon: "book-open-01" },
  { title: "Fazer a lição de casa",          points: 20,  frequency: :daily,  category: :escola, icon: "notebook-01" },

  # Semanal
  { title: "Organizar o quarto",             points: 30,  frequency: :weekly, category: :casa,   icon: "broom" },
  { title: "Ajudar com a roupa lavada",      points: 25,  frequency: :weekly, category: :casa,   icon: "shirt-01" },
  { title: "Lavar a louça do jantar",        points: 30,  frequency: :weekly, category: :casa,   icon: "dish" },
  { title: "Aprender um assunto novo",       points: 40,  frequency: :weekly, category: :escola, icon: "lightbulb-01" },
  { title: "Semana inteira sem brigar",      points: 50,  frequency: :weekly, category: :rotina, icon: "happy" },

  # Marcos
  { title: "Tirar nota boa em prova",        points: 100, frequency: :once,   category: :escola, icon: "medal-01" },
  { title: "Apresentação na escola",         points: 80,  frequency: :once,   category: :escola, icon: "mic-01" }
]

missions.each { |m| GlobalTask.create!(family: family, **m) }

puts "Creating Today's Profile Tasks..."
daily_tasks = family.global_tasks.where(frequency: :daily).to_a
daily_tasks.each do |task|
  kids.each do |kid|
    next if rand < 0.15 # ~85% of daily tasks assigned to each kid today
    ProfileTask.create!(profile: kid, global_task: task, status: :pending, assigned_date: Date.current)
  end
end

# A few awaiting approval to give parent something to triage on first login
ProfileTask.create!(profile: theo, global_task: family.global_tasks.find_by(title: "Fazer a lição de casa"),
                    status: :awaiting_approval, assigned_date: Date.current,
                    submission_comment: "Terminei a matemática toda!")
ProfileTask.create!(profile: lis, global_task: family.global_tasks.find_by(title: "Arrumar a cama"),
                    status: :awaiting_approval, assigned_date: Date.current)
ProfileTask.create!(profile: laura, global_task: family.global_tasks.find_by(title: "Ler 15 minutos"),
                    status: :awaiting_approval, assigned_date: Date.current,
                    submission_comment: "Li mais que 15min hoje 📖")

puts "Creating Rewards..."
cats = family.categories.index_by(&:name)
rewards = [
  # Quick wins (1–3 dias de estrelas)
  { title: "Escolher a música do carro",  cost: 20,    icon: "music-note-01",   category: "Experiências" },
  { title: "30 minutos de celular",       cost: 30,    icon: "smart-phone-01",  category: "Telinha" },
  { title: "Sorvete com cobertura",       cost: 40,    icon: "ice-cream-01",    category: "Docinhos" },
  { title: "Dormir 30min mais tarde",     cost: 50,    icon: "moon-02",         category: "Experiências" },
  { title: "Escolher o filme da família", cost: 60,    icon: "film-01",         category: "Experiências" },
  { title: "1 hora de tablet",            cost: 70,    icon: "tablet-01",       category: "Telinha" },
  { title: "Passeio na sorveteria",       cost: 80,    icon: "ice-cream-02",    category: "Passeios" },

  # Mid-tier (semanal/quinzenal)
  { title: "Pizza no jantar",             cost: 150,   icon: "pizza-01",        category: "Experiências" },
  { title: "Dia no shopping",             cost: 200,   icon: "shopping-bag-01", category: "Passeios" },
  { title: "Livro novo",                  cost: 250,   icon: "book-02",         category: "Brinquedos" },
  { title: "Festa do pijama",             cost: 300,   icon: "moon-01",         category: "Experiências" },

  # Aspirational
  { title: "LEGO grande",                 cost: 1500,  icon: "cube",            category: "Brinquedos" },
  { title: "Beto Carrero World",          cost: 5000,  icon: "ferris-wheel",    category: "Passeios" },
  { title: "Tablet novo",                 cost: 8000,  icon: "tablet-01",       category: "Brinquedos" }
]

rewards.each do |r|
  Reward.create!(
    family: family,
    title:    r[:title],
    cost:     r[:cost],
    icon:     r[:icon],
    category: cats.fetch(r[:category])
  )
end

puts "Seed complete! 🌟"
puts "  Família Budal — login: familia@budal.dev / supersecret1234"
puts "  Kids: Theo (sky), Lis (rose), Laura (lilac) — 50⭐ each — PINs: 1111/2222/3333"
puts "  #{family.global_tasks.count} missions, #{family.rewards.count} rewards, #{family.categories.count} categories"
