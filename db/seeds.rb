# =============================================================================
# Seed oficial — Família Budal (uso real)
#
# Filosofia: COMEÇAR ENXUTO. Só as tarefas mais prioritárias — as âncoras
# pessoais não-negociáveis de cada criança + os deveres de escola + a oração da
# família. Tudo diário, fácil de manter no dia 1. Conforme o hábito pega, novas
# missões (zona da casa, cuidado do Simba, chores semanais, bônus) entram aos
# poucos pelo painel dos pais — sem precisar editar este arquivo.
#
# A lojinha (recompensas) já começa completa, em 4 tiers, pra ter metas de todo
# tamanho desde o primeiro dia: micro (dopamina diária) → médio (meta semanal)
# → aspiracional (wishlist longa) → família (coletivo).
# =============================================================================

# Idempotent: skip wipe + seed if any Family already exists, unless SEED_FORCE=1.
if Family.exists? && ENV["SEED_FORCE"] != "1"
  puts "↪ Seed skipped: #{Family.count} family/families already present. Use SEED_FORCE=1 to re-seed."
  # Even when host data exists, refresh the Academy curriculum (idempotent).
  load Rails.root.join("db/seeds/academy.rb")
  exit
end

if ENV["SEED_FORCE"] == "1"
  puts "⚠ SEED_FORCE=1 — wiping all data..."
  [ ActivityLog, Redemption, ProfileTask, GlobalTaskAssignment, Reward, Category, GlobalTask, ProfileInterest, Profile, ProfileInvitation, Family ].each(&:delete_all)
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

# Escala de pontos por esforço/idade:
#   Lis (4y)   diária 10–15
#   Theo (7y)  diária 10–15
#   Laura (11y) diária 10–25
#
# Conjunto inicial = ÂNCORAS PESSOAIS (rotina não-negociável) + ESCOLA. Tudo
# diário. As zonas da casa, o cuidado do Simba e os chores semanais ficam de
# fora por enquanto — entram depois pelo painel dos pais.

lis_missions = [
  # Âncoras pessoais (3)
  { title: "Escovar dentinhos 2x (manhã + noite)", points: 10, frequency: :daily, category: :saude,  icon: "tooth-01" },
  { title: "Rotina da manhã (lavar rosto + pentear + banheiro)", points: 15, frequency: :daily, category: :rotina, icon: "soap" },
  { title: "Meu cantinho (roupa no cesto + sapatos + cama com ajuda)", points: 15, frequency: :daily, category: :casa, icon: "bed-bunk" },
  # Escola (1) — na idade da Lis, "escola" é aprender brincando
  { title: "Aprender algo novo (10 min)",     points: 15, frequency: :daily, category: :escola, icon: "book-open-01" }
]

theo_missions = [
  # Âncoras pessoais (3)
  { title: "Escovar dentes 2x (manhã + noite)", points: 10, frequency: :daily, category: :saude,  icon: "tooth-01" },
  { title: "Banho sozinho + cama pronta",      points: 15, frequency: :daily, category: :rotina, icon: "shower-head" },
  { title: "Prep escola (mochila + roupa amanhã + agenda)", points: 15, frequency: :daily, category: :casa, icon: "school-bag-01" },
  # Escola (2)
  { title: "Lição de casa antes da brincadeira", points: 15, frequency: :daily, category: :escola, icon: "notebook-01" },
  { title: "Leitura solo (15 min antes de dormir)", points: 15, frequency: :daily, category: :escola, icon: "book-02" }
]

laura_missions = [
  # Âncoras pessoais (3)
  { title: "Skincare e higiene completa",     points: 10, frequency: :daily,  category: :saude,  icon: "soap" },
  { title: "Mochila e uniforme prontos pra amanhã", points: 10, frequency: :daily, category: :casa, icon: "school-bag-01" },
  { title: "Quarto organizado, chão livre",   points: 15, frequency: :daily,  category: :casa,   icon: "broom" },
  # Escola (2)
  { title: "Lição de casa antes do lazer",    points: 20, frequency: :daily,  category: :escola, icon: "notebook-01" },
  { title: "Estudar 30 min + ler 20 min antes de dormir", points: 25, frequency: :daily, category: :escola, icon: "book-02" }
]

# Compartilhada — rotina espiritual da família, vale pra todos.
shared_missions = [
  { title: "Fazer a oração antes de dormir",  points: 5, frequency: :daily, category: :rotina, icon: "praying-hands-01" }
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
# Aspiracional (meta longa) · Família (coletivo). Total ~28 itens, sem overlap.
rewards = [
  # Micro (30-80) — pequenas conquistas diárias
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
puts "  Pais: Mamãe (rose, PIN 1111) · Papai (sky, PIN 2222)"
puts "  Kids: Theo (sky), Lis (rose), Laura (lilac) — 0⭐ each — PINs: 1111/2222/3333"
puts "  Missions per kid: Lis=#{lis_missions.size}, Theo=#{theo_missions.size}, Laura=#{laura_missions.size} (+#{shared_missions.size} compartilhada) — só diárias, comece enxuto"
puts "  Total: #{family.global_tasks.count} missions, #{family.rewards.count} rewards, #{family.categories.count} categories"

load Rails.root.join("db/seeds/academy.rb")
