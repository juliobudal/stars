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
                        color: "sky",   points: 0, pin: "1111")
lis   = Profile.create!(family: family, name: "Lis",   role: :child,
                        color: "rose",  points: 0, pin: "2222")
laura = Profile.create!(family: family, name: "Laura", role: :child,
                        color: "lilac", points: 0, pin: "3333")

puts "Creating Global Tasks (per-kid via assignments)..."

# Point scale by effort/age:
#   Lis (4y)   daily 5–15, weekly 20–30
#   Theo (7y)  daily 5–15, weekly 20–40
#   Laura (11y) daily 5–20, weekly 25–50

# =============================================================================
# Método 3-2-1 Familiar: cada kid dono de zona clara → tira peso da mamãe.
#   3 âncoras diárias (rotina pessoal não-negociável)
#   2 deveres de zona (contribuição à casa)
#   1 bônus/desafio
# Zonas: Lis = cantinho próprio + água Simba · Theo = louça/cozinha + comida Simba
#        Laura = sala/banheiros + passeio Simba
# =============================================================================

lis_missions = [
  # Âncoras pessoais (3)
  { title: "Escovar dentinhos 2x (manhã + noite)", points: 10, frequency: :daily, category: :saude,  icon: "tooth-01" },
  { title: "Rotina da manhã (lavar rosto + pentear + banheiro)", points: 15, frequency: :daily, category: :rotina, icon: "soap" },
  { title: "Meu cantinho (roupa no cesto + sapatos + cama com ajuda)", points: 15, frequency: :daily, category: :casa, icon: "bed-bunk" },
  # Zona Lis (2): cantinho + Simba água
  { title: "Trocar a água do Simba",          points: 10, frequency: :daily,  category: :casa,   icon: "drink" },
  { title: "Comer toda a verdurinha + beber água do dia", points: 15, frequency: :daily, category: :saude, icon: "broccoli" },
  # Bônus (1)
  { title: "Aprender algo novo (10 min)",     points: 15, frequency: :daily,  category: :escola, icon: "book-open-01" },
  # Semanais — contribuição leve à casa (2)
  { title: "Ajudar a regar as plantinhas",    points: 20, frequency: :weekly, category: :casa,   icon: "plant-02" },
  { title: "Ajudar a guardar as compras",     points: 25, frequency: :weekly, category: :casa,   icon: "shopping-bag-01" }
]

theo_missions = [
  # Âncoras pessoais (3)
  { title: "Escovar dentes 2x (manhã + noite)", points: 10, frequency: :daily, category: :saude,  icon: "tooth-01" },
  { title: "Banho sozinho + cama pronta",      points: 15, frequency: :daily, category: :rotina, icon: "shower-head" },
  { title: "Prep escola (mochila + roupa amanhã + agenda)", points: 15, frequency: :daily, category: :casa, icon: "school-bag-01" },
  # Zona Theo (2): cozinha + Simba comida
  { title: "Secar a louça do jantar",         points: 15, frequency: :daily,  category: :casa,   icon: "dish-washer" },
  { title: "Dar comida pro Simba (manhã + noite)", points: 10, frequency: :daily, category: :casa, icon: "happy-01" },
  # Estudo (2)
  { title: "Lição de casa antes da brincadeira", points: 15, frequency: :daily, category: :escola, icon: "notebook-01" },
  { title: "Leitura solo (15 min antes de dormir)", points: 15, frequency: :daily, category: :escola, icon: "book-02" },
  # Bônus (1)
  { title: "Praticar inglês no Duolingo (10 min)", points: 10, frequency: :daily, category: :escola, icon: "language-skill" },
  # Semanal rotativa — chore real + banho do Simba
  { title: "Chore semanal rotativa (Caçada Lixo / Estante / Espelho)", points: 25, frequency: :weekly, category: :casa, icon: "broom" },
  { title: "Dar banho no Simba",              points: 40, frequency: :weekly, category: :casa,   icon: "shower-head" }
]

laura_missions = [
  # Âncoras pessoais (3)
  { title: "Skincare e higiene completa",     points: 10, frequency: :daily,  category: :saude,  icon: "soap" },
  { title: "Mochila e uniforme prontos pra amanhã", points: 10, frequency: :daily, category: :casa, icon: "school-bag-01" },
  { title: "Quarto organizado, chão livre",   points: 15, frequency: :daily,  category: :casa,   icon: "broom" },
  # Zona Laura (2): louça pesada + passeio Simba
  { title: "Lavar a louça do jantar",         points: 20, frequency: :daily,  category: :casa,   icon: "dish-washer" },
  { title: "Levar o Simba pra passear",       points: 20, frequency: :daily,  category: :casa,   icon: "happy-01" },
  # Estudo (2)
  { title: "Lição de casa antes do lazer",    points: 20, frequency: :daily,  category: :escola, icon: "notebook-01" },
  { title: "Estudar 30 min + ler 20 min antes de dormir", points: 25, frequency: :daily, category: :escola, icon: "book-02" },
  # Bônus (1)
  { title: "Praticar inglês no Duolingo (15 min)", points: 15, frequency: :daily, category: :escola, icon: "language-skill" },
  # Semanal — chore rotativa + chapéu de irmã rotativo
  { title: "Chore semanal rotativa (Sala / Geladeira / Banheiros)", points: 35, frequency: :weekly, category: :casa, icon: "broom" },
  { title: "Chapéu de irmã: ler pra Lis OU ajudar Theo na lição", points: 30, frequency: :weekly, category: :rotina, icon: "happy-01" },
  { title: "Cozinhar uma receita completa com supervisão", points: 50, frequency: :weekly, category: :outro, icon: "cake-slice" }
]

# Compartilhadas — rotinas familiares mínimas + reposições do "cada um cuida".
shared_missions = [
  { title: "Fazer a oração antes de dormir",  points: 5,  frequency: :daily,  category: :rotina, icon: "praying-hands-01" },
  { title: "Dia sem brigar com os irmãos",    points: 10, frequency: :daily,  category: :rotina, icon: "happy" },
  { title: "Repor o gelo no congelador",      points: 20, frequency: :weekly, category: :casa,   icon: "drink" },
  { title: "Repor bala fini caseira",         points: 20, frequency: :weekly, category: :casa,   icon: "cake-slice" }
]

per_kid_missions = { lis => lis_missions, theo => theo_missions, laura => laura_missions }

per_kid_missions.each do |kid, missions|
  missions.each do |attrs|
    task = GlobalTask.create!(family: family, **attrs)
    GlobalTaskAssignment.create!(global_task: task, profile: kid)
  end
end

shared_missions.each do |attrs|
  task = GlobalTask.create!(family: family, **attrs)
  per_kid_missions.keys.each do |kid|
    GlobalTaskAssignment.create!(global_task: task, profile: kid)
  end
end

puts "Creating Rewards..."
cats = family.categories.index_by(&:name)
# Estrutura enxuta em 4 tiers: Micro (dopamina diária) · Médio (meta semanal) ·
# Aspiracional (meta longa) · Família (coletivo). Total ~30 itens, sem overlap.
rewards = [
  # Micro (15-80) — pequenas conquistas diárias
  { title: "30 min extra de celular/tablet",           cost: 30,    icon: "smart-phone-01",   category: "Telinha" },
  { title: "Escolher o que assistir na TV à noite",    cost: 30,    icon: "tv-01",            category: "Experiências" },
  { title: "Sobremesa especial no jantar",             cost: 35,    icon: "cake-slice",       category: "Docinhos" },
  { title: "Sorvete com cobertura",                    cost: 40,    icon: "ice-cream-01",     category: "Docinhos" },
  { title: "Escolher o jantar da família",             cost: 50,    icon: "pizza-01",         category: "Experiências" },
  { title: "Dormir 30 min mais tarde",                 cost: 50,    icon: "moon-02",          category: "Experiências" },
  { title: "Adesivos / figurinhas",                    cost: 60,    icon: "sticker",          category: "Brinquedos" },
  { title: "Lanche favorito (McDonald's/BK)",          cost: 80,    icon: "hamburger-01",     category: "Docinhos" },

  # Médio (100-400) — meta semanal/quinzenal
  { title: "Slime, massinha ou esmalte novo",          cost: 100,   icon: "puzzle",           category: "Brinquedos" },
  { title: "Hot Wheels ou acessório de cabelo",        cost: 120,   icon: "car-01",           category: "Brinquedos" },
  { title: "Saída pro parque com 1 dos pais",          cost: 120,   icon: "ferris-wheel",     category: "Passeios" },
  { title: "Almoço fora só com 1 dos pais",            cost: 180,   icon: "dish-01",          category: "Experiências" },
  { title: "Livro novo (escolha livre)",               cost: 200,   icon: "book-02",          category: "Brinquedos" },
  { title: "Tarde no shopping com mãe ou pai",         cost: 200,   icon: "shopping-bag-01",  category: "Passeios" },
  { title: "Brinquedo médio (pelúcia / boneca / action)", cost: 300, icon: "happy-01",        category: "Brinquedos" },
  { title: "Maquiagem teen (Laura)",                   cost: 300,   icon: "lipstick",         category: "Brinquedos" },
  { title: "Jogo de tabuleiro novo",                   cost: 350,   icon: "puzzle",           category: "Brinquedos" },
  { title: "Cinema com pipoca grande",                 cost: 400,   icon: "popcorn",          category: "Passeios" },

  # Aspiracional (800+) — wishlist longa
  { title: "LEGO escolha livre",                       cost: 800,   icon: "cube",             category: "Brinquedos" },
  { title: "Patinete ou skate novo",                   cost: 1200,  icon: "scooter-02",       category: "Brinquedos" },
  { title: "Microscópio ou kit de ciência",            cost: 1500,  icon: "microscope",       category: "Brinquedos" },
  { title: "Bicicleta nova",                           cost: 3000,  icon: "bicycle",          category: "Brinquedos" },
  { title: "Máquina de sorvete",                       cost: 5000,  icon: "ice-cream-01",     category: "Brinquedos" },
  { title: "Nintendo Switch",                          cost: 8000,  icon: "nintendo-switch",  category: "Telinha" },
  { title: "Celular novo (quando idade permitir)",     cost: 12000, icon: "smart-phone-01",   category: "Telinha" },

  # Família — coletivo (todos somam, todos ganham)
  { title: "[Família] Pizza no jantar de sexta",       cost: 150,   icon: "pizza-01",         category: "Experiências" },
  { title: "[Família] Cinema todo mundo junto",        cost: 400,   icon: "film-01",          category: "Passeios" },
  { title: "[Família] Viagem pequena (2-3 dias)",      cost: 6000,  icon: "rocket",           category: "Passeios" }
]

rewards.each do |r|
  Reward.create!(
    family: family,
    title:    r[:title],
    cost:     r[:cost],
    icon:     r[:icon],
    category: cats.fetch(r[:category]),
    collective: r[:title].start_with?("[Família]")
  )
end

puts "Seed complete! 🌟"
puts "  Família Budal — login: familia@budal.dev / supersecret1234"
puts "  Kids: Theo (sky), Lis (rose), Laura (lilac) — 0⭐ each — PINs: 1111/2222/3333"
puts "  Missions per kid: Lis=#{lis_missions.size}, Theo=#{theo_missions.size}, Laura=#{laura_missions.size} (+#{shared_missions.size} compartilhadas)"
puts "  Total: #{family.global_tasks.count} missions, #{family.rewards.count} rewards, #{family.categories.count} categories"
