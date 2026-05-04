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

puts "Creating Global Tasks (per-kid via assignments)..."

# Point scale by effort/age:
#   Lis (4y)   daily 5–15, weekly 20–30
#   Theo (7y)  daily 5–15, weekly 20–40
#   Laura (11y) daily 5–20, weekly 25–50

lis_missions = [
  # Autocuidado (diária)
  { title: "Dentinhos brilhando (manhã)",     points: 5,  frequency: :daily,  category: :saude,  icon: "tooth-01" },
  { title: "Dentinhos brilhando (noite)",     points: 5,  frequency: :daily,  category: :saude,  icon: "tooth-01" },
  { title: "Lavar a carinha",                 points: 5,  frequency: :daily,  category: :saude,  icon: "soap" },
  { title: "Pentear o cabelo",                points: 5,  frequency: :daily,  category: :rotina, icon: "comb" },
  { title: "Ir no banheiro sozinha",          points: 10, frequency: :daily,  category: :rotina, icon: "happy-01" },
  # Casa (diária)
  { title: "Brinquedos vão pra casinha",      points: 10, frequency: :daily,  category: :casa,   icon: "puzzle" },
  { title: "Roupinha no cesto",               points: 5,  frequency: :daily,  category: :casa,   icon: "shirt-01" },
  { title: "Pratinho na pia",                 points: 5,  frequency: :daily,  category: :casa,   icon: "dish-01" },
  { title: "Guardar sapatinhos no lugar",     points: 5,  frequency: :daily,  category: :casa,   icon: "shoes-01" },
  { title: "Fazer a caminha (com ajuda)",     points: 10, frequency: :daily,  category: :casa,   icon: "bed-bunk" },
  # Alimentação (diária)
  { title: "Comer toda a verdurinha",         points: 15, frequency: :daily,  category: :saude,  icon: "broccoli" },
  { title: "Beber 4 copos de água",           points: 10, frequency: :daily,  category: :saude,  icon: "drink" },
  { title: "Tomar o café da manhã sem reclamar", points: 10, frequency: :daily, category: :saude, icon: "coffee-01" },
  # Aprendizado e brincar (diária)
  { title: "Aprender algo novo (10 min)",     points: 15, frequency: :daily,  category: :escola, icon: "book-open-01" },
  { title: "Brincar pra valer (20 min sem tela)", points: 10, frequency: :daily, category: :rotina, icon: "happy-01" },
  { title: "Cantar uma música nova",          points: 10, frequency: :daily,  category: :rotina, icon: "music-note-01" },
  { title: "Fazer um desenho do dia",         points: 10, frequency: :daily,  category: :rotina, icon: "pencil-edit-01" },
  # Semanais
  { title: "Ajudar a regar as plantinhas",    points: 20, frequency: :weekly, category: :casa,   icon: "plant-02" },
  { title: "Escolher uma roupa pra doar",     points: 25, frequency: :weekly, category: :outro,  icon: "gift" },
  { title: "Ajudar a guardar as compras",     points: 25, frequency: :weekly, category: :casa,   icon: "shopping-bag-01" },
  { title: "Tomar banho sem reclamar 5x na semana", points: 30, frequency: :weekly, category: :saude, icon: "shower-head" }
]

theo_missions = [
  # Autocuidado (diária)
  { title: "Expedição Dentes Limpos (manhã)", points: 5,  frequency: :daily,  category: :saude,  icon: "tooth-01" },
  { title: "Expedição Dentes Limpos (noite)", points: 5,  frequency: :daily,  category: :saude,  icon: "tooth-01" },
  { title: "Tomar banho sem ser chamado",     points: 10, frequency: :daily,  category: :saude,  icon: "shower-head" },
  { title: "Beber 6 copos de água",           points: 10, frequency: :daily,  category: :saude,  icon: "drink" },
  # Casa (diária)
  { title: "Operação Cama Pronta",            points: 10, frequency: :daily,  category: :casa,   icon: "bed-bunk" },
  { title: "Missão Mochila no Lugar",         points: 5,  frequency: :daily,  category: :casa,   icon: "school-bag-01" },
  { title: "Quest do Pratinho",               points: 5,  frequency: :daily,  category: :casa,   icon: "dish-01" },
  { title: "Protocolo Roupa Pronta (amanhã)", points: 10, frequency: :daily,  category: :casa,   icon: "shirt-01" },
  { title: "Sapatos no rack ao chegar",       points: 5,  frequency: :daily,  category: :casa,   icon: "shoes-01" },
  # Escola (diária)
  { title: "Lição de casa antes da brincadeira", points: 15, frequency: :daily, category: :escola, icon: "notebook-01" },
  { title: "Avisar prova/trabalho com antecedência", points: 15, frequency: :daily, category: :escola, icon: "alarm-clock" },
  { title: "Conferir agenda da escola",       points: 5,  frequency: :daily,  category: :escola, icon: "calendar-01" },
  # Aprendizado (diária)
  { title: "Aprender algo novo (15 min)",     points: 15, frequency: :daily,  category: :escola, icon: "book-open-01" },
  { title: "Leitura solo (15 min antes de dormir)", points: 15, frequency: :daily, category: :escola, icon: "book-02" },
  { title: "Treino de tabuada/cálculo (5 min)", points: 10, frequency: :daily, category: :escola, icon: "calculator" },
  { title: "Praticar inglês no Duolingo (10 min)", points: 10, frequency: :daily, category: :escola, icon: "language-skill" },
  # Atitude (diária)
  { title: "Falar uma coisa boa do irmão/irmã", points: 10, frequency: :daily, category: :rotina, icon: "happy" },
  { title: "Pedir 'por favor' e 'obrigado' o dia todo", points: 10, frequency: :daily, category: :rotina, icon: "happy-01" },
  # Semanais (rotativas — sorteio dominical)
  { title: "Caçada ao Lixo",                  points: 25, frequency: :weekly, category: :casa,   icon: "delete-02" },
  { title: "Resgate das Plantas",             points: 25, frequency: :weekly, category: :casa,   icon: "plant-02" },
  { title: "Missão Estante",                  points: 30, frequency: :weekly, category: :casa,   icon: "book-02" },
  { title: "Patrulha do Espelho",             points: 25, frequency: :weekly, category: :casa,   icon: "mirror" },
  { title: "Limpar a mesa da cozinha após jantar", points: 25, frequency: :weekly, category: :casa, icon: "dish-washer" },
  { title: "Organizar tênis e sapatos da entrada", points: 20, frequency: :weekly, category: :casa, icon: "shoes-01" },
  { title: "Tirar o pó dos móveis baixos",    points: 25, frequency: :weekly, category: :casa,   icon: "broom" },
  # Semanais — desafios
  { title: "Aprender uma palavra nova em inglês", points: 30, frequency: :weekly, category: :escola, icon: "language-skill" },
  { title: "Cozinhar algo simples com adulto", points: 40, frequency: :weekly, category: :outro, icon: "cake-slice" },
  { title: "Andar de bicicleta/patinete 2x na semana", points: 35, frequency: :weekly, category: :saude, icon: "bicycle" }
]

laura_missions = [
  # Autocuidado e autonomia (diária)
  { title: "Quarto organizado, chão livre",   points: 15, frequency: :daily,  category: :casa,   icon: "broom" },
  { title: "Mochila e uniforme prontos pra amanhã", points: 10, frequency: :daily, category: :casa, icon: "school-bag-01" },
  { title: "Prato à pia sem ser pedido",      points: 5,  frequency: :daily,  category: :casa,   icon: "dish-01" },
  { title: "Cuidar dos próprios eletrônicos", points: 10, frequency: :daily,  category: :rotina, icon: "smart-phone-01" },
  { title: "Beber 8 copos de água",           points: 10, frequency: :daily,  category: :saude,  icon: "drink" },
  { title: "Skincare e higiene completa",     points: 10, frequency: :daily,  category: :saude,  icon: "soap" },
  # Escola (diária)
  { title: "Lição de casa antes do lazer",    points: 20, frequency: :daily,  category: :escola, icon: "notebook-01" },
  { title: "Estudar 30 min de matéria difícil", points: 20, frequency: :daily, category: :escola, icon: "book-02" },
  { title: "Conferir agenda e prazos da semana", points: 10, frequency: :daily, category: :escola, icon: "calendar-01" },
  # Aprendizado (diária)
  { title: "Aprender algo novo (20 min)",     points: 20, frequency: :daily,  category: :escola, icon: "book-open-01" },
  { title: "Leitura silenciosa (20 min antes de dormir)", points: 20, frequency: :daily, category: :escola, icon: "book-02" },
  { title: "Praticar inglês no Duolingo (15 min)", points: 15, frequency: :daily, category: :escola, icon: "language-skill" },
  { title: "Escrever 3 frases no diário (PT/EN)", points: 15, frequency: :daily, category: :escola, icon: "pencil-edit-01" },
  # Atitude (diária)
  { title: "Falar com Theo/Lis com paciência mesmo cansada", points: 15, frequency: :daily, category: :rotina, icon: "happy" },
  { title: "Ajudar sem ser pedido (1x no dia)", points: 15, frequency: :daily, category: :rotina, icon: "happy-01" },
  # Semanais — rotativas
  { title: "Organizar a sala comum",          points: 35, frequency: :weekly, category: :casa,   icon: "broom" },
  { title: "Lixos dos banheiros",             points: 25, frequency: :weekly, category: :casa,   icon: "delete-02" },
  { title: "Lista de compras da semana",      points: 30, frequency: :weekly, category: :casa,   icon: "shopping-bag-01" },
  { title: "Tirar o pó das estantes altas",   points: 30, frequency: :weekly, category: :casa,   icon: "broom" },
  { title: "Limpar e organizar a geladeira",  points: 35, frequency: :weekly, category: :casa,   icon: "dish-washer" },
  { title: "Dobrar e guardar a própria roupa", points: 30, frequency: :weekly, category: :casa,  icon: "shirt-01" },
  # Semanais — chapéu de irmã
  { title: "Ler historinha pra Lis",          points: 25, frequency: :weekly, category: :rotina, icon: "book-open-01" },
  { title: "Ajudar Theo na lição",            points: 30, frequency: :weekly, category: :escola, icon: "notebook-01" },
  { title: "Brincar com Lis (20 min)",        points: 25, frequency: :weekly, category: :rotina, icon: "happy-01" },
  { title: "Ajudar Lis no pijama/escovação",  points: 25, frequency: :weekly, category: :rotina, icon: "tooth-01" },
  # Semanais — desafios
  { title: "Aprender 5 palavras novas em inglês", points: 40, frequency: :weekly, category: :escola, icon: "language-skill" },
  { title: "Cozinhar uma receita completa com supervisão", points: 50, frequency: :weekly, category: :outro, icon: "cake-slice" },
  { title: "Apresentar pra família algo aprendido na semana", points: 40, frequency: :weekly, category: :escola, icon: "happy" },
  { title: "Praticar instrumento/hobby (3x na semana)", points: 50, frequency: :weekly, category: :outro, icon: "music-note-01" }
]

per_kid_missions = { lis => lis_missions, theo => theo_missions, laura => laura_missions }

per_kid_missions.each do |kid, missions|
  missions.each do |attrs|
    task = GlobalTask.create!(family: family, **attrs)
    GlobalTaskAssignment.create!(global_task: task, profile: kid)
  end
end

puts "Creating today's ProfileTasks for each kid..."
per_kid_missions.each do |kid, missions|
  daily_titles = missions.select { |m| m[:frequency] == :daily }.map { |m| m[:title] }
  family.global_tasks.where(title: daily_titles).find_each do |task|
    next if rand < 0.15 # ~85% assigned today
    ProfileTask.create!(profile: kid, global_task: task, status: :pending, assigned_date: Date.current)
  end
end

puts "Seeding a few awaiting_approval items for parent triage..."
[
  [ lis,   "Dentinhos brilhando (manhã)", "Escovei sozinha! ✨" ],
  [ lis,   "Fazer um desenho do dia",     nil ],
  [ theo,  "Operação Cama Pronta",        "Cama prontíssima!" ],
  [ theo,  "Leitura solo (15 min antes de dormir)", "Li mais que 15min 📖" ],
  [ laura, "Quarto organizado, chão livre", "Tá brilhando" ],
  [ laura, "Praticar inglês no Duolingo (15 min)", nil ]
].each do |profile, title, comment|
  task = family.global_tasks.find_by(title: title)
  next unless task

  existing = ProfileTask.find_by(profile: profile, global_task: task, assigned_date: Date.current)
  if existing
    existing.update!(status: :awaiting_approval, submission_comment: comment)
  else
    ProfileTask.create!(profile: profile, global_task: task,
                        status: :awaiting_approval, assigned_date: Date.current,
                        submission_comment: comment)
  end
end

puts "Creating Rewards..."
cats = family.categories.index_by(&:name)
rewards = [
  # Experiências do dia-a-dia
  { title: "Pedir uma música pro Alexa/Spotify",       cost: 15,    icon: "voice",            category: "Experiências" },
  { title: "Escolher a música do carro",               cost: 20,    icon: "music-note-01",    category: "Experiências" },
  { title: "Ser o primeiro a se servir no jantar",     cost: 20,    icon: "dish-01",          category: "Experiências" },
  { title: "Sentar no banco da frente do carro",       cost: 25,    icon: "car-01",           category: "Experiências" },
  { title: "Escolher o que assistir na TV à noite",    cost: 30,    icon: "tv-01",            category: "Experiências" },
  { title: "Escolher o jantar da família",             cost: 50,    icon: "pizza-01",         category: "Experiências" },
  { title: "Escolher o filme da família",              cost: 60,    icon: "film-01",          category: "Experiências" },

  # Tela e tempo
  { title: "30 min extra de celular/tablet",           cost: 30,    icon: "smart-phone-01",   category: "Telinha" },
  { title: "Dormir 30 min mais tarde",                 cost: 50,    icon: "moon-02",          category: "Experiências" },
  { title: "1 hora de tablet livre",                   cost: 70,    icon: "tablet-01",        category: "Telinha" },
  { title: "Dormir na cama dos pais (noite especial)", cost: 80,    icon: "bed-double",       category: "Experiências" },
  { title: "Acordar mais tarde no fim de semana",      cost: 80,    icon: "alarm-clock",      category: "Experiências" },

  # Docinhos e comidinhas
  { title: "Sobremesa especial no jantar",             cost: 35,    icon: "cake-slice",       category: "Docinhos" },
  { title: "Sorvete com cobertura",                    cost: 40,    icon: "ice-cream-01",     category: "Docinhos" },
  { title: "Cozinhar uma sobremesa com adulto",        cost: 50,    icon: "cake-slice",       category: "Experiências" },
  { title: "Café da manhã na cama",                    cost: 60,    icon: "coffee-01",        category: "Experiências" },
  { title: "Lanche favorito (McDonald's/BK)",          cost: 80,    icon: "hamburger-01",     category: "Docinhos" },
  { title: "Pedir delivery do prato favorito",         cost: 120,   icon: "delivery-truck-01", category: "Docinhos" },

  # Conexão (tempo de qualidade)
  { title: "Ligar pra avó/avô e bater papo",           cost: 30,    icon: "phone-call",       category: "Experiências" },
  { title: "Ir junto buscar irmão na escola",          cost: 40,    icon: "school-bag-01",    category: "Experiências" },
  { title: "30 min só com a mamãe (sem irmãos)",       cost: 80,    icon: "happy",            category: "Experiências" },
  { title: "30 min só com o papai (sem irmãos)",       cost: 80,    icon: "happy",            category: "Experiências" },
  { title: "Visita aos avós",                          cost: 100,   icon: "gift",             category: "Passeios" },
  { title: "Adotar uma planta que é 'sua'",            cost: 100,   icon: "plant-02",         category: "Outro" },
  { title: "Saída pro parque com 1 dos pais",          cost: 120,   icon: "ferris-wheel",     category: "Passeios" },
  { title: "Convidar 1 amigo pra brincar em casa",     cost: 150,   icon: "happy-01",         category: "Experiências" },
  { title: "Almoço fora só com 1 dos pais",            cost: 180,   icon: "dish-01",          category: "Experiências" },
  { title: "Tarde no shopping com mãe ou pai",         cost: 200,   icon: "shopping-bag-01",  category: "Passeios" },
  { title: "Festa do pijama com primo/amigo",          cost: 400,   icon: "moon-01",          category: "Experiências" },

  # Coisinhas — pequenos achados
  { title: "Adesivos/stickers",                        cost: 60,    icon: "sticker",          category: "Brinquedos" },
  { title: "Esmalte novo",                             cost: 80,    icon: "lipstick",         category: "Brinquedos" },
  { title: "Pacote de figurinhas/cards",               cost: 80,    icon: "gift-card",        category: "Brinquedos" },
  { title: "Pulseira ou colar simples",                cost: 80,    icon: "bracelet",         category: "Brinquedos" },
  { title: "Slime ou massinha nova",                   cost: 100,   icon: "puzzle",           category: "Brinquedos" },
  { title: "Caneta ou estojo novo",                    cost: 100,   icon: "pencil-edit-01",   category: "Brinquedos" },
  { title: "Carrinho Hot Wheels",                      cost: 120,   icon: "car-01",           category: "Brinquedos" },
  { title: "Acessório pra cabelo bonito",              cost: 120,   icon: "bow",              category: "Brinquedos" },

  # Coisinhas — médios
  { title: "Livro novo (escolha livre)",               cost: 200,   icon: "book-02",          category: "Brinquedos" },
  { title: "Pelúcia média",                            cost: 200,   icon: "happy-01",         category: "Brinquedos" },
  { title: "Material de arte (kit pintura, etc)",      cost: 250,   icon: "paint-brush",      category: "Brinquedos" },
  { title: "Boneca / action figure",                   cost: 300,   icon: "happy-01",         category: "Brinquedos" },
  { title: "Maquiagem infantil/teen (Laura)",          cost: 300,   icon: "lipstick",         category: "Brinquedos" },
  { title: "Jogo de tabuleiro novo",                   cost: 350,   icon: "puzzle",           category: "Brinquedos" },

  # Vestir
  { title: "Camiseta nova escolhida por você",         cost: 300,   icon: "shirt-01",         category: "Outro" },
  { title: "Roupa especial pra ocasião",               cost: 400,   icon: "shirt-01",         category: "Outro" },
  { title: "Tênis novo",                               cost: 600,   icon: "shoes-01",         category: "Outro" },

  # Específicos da Laura
  { title: "Decidir decoração de um cantinho do quarto (Laura)", cost: 300, icon: "palette", category: "Outro" },
  { title: "Conta no Spotify/streaming dela (Laura)",  cost: 400,   icon: "music-note-01",    category: "Telinha" },
  { title: "Cinema com amiga sem pais (Laura)",        cost: 500,   icon: "film-01",          category: "Passeios" },
  { title: "Fone de ouvido bluetooth (Laura)",         cost: 600,   icon: "headphones",       category: "Telinha" },
  { title: "Pintar uma parede do quarto (Laura)",      cost: 800,   icon: "paint-brush",      category: "Outro" },
  { title: "Curso online de algo que ela escolha (Laura)", cost: 800, icon: "graduation-scroll", category: "Outro" },

  # Aspiracionais — passeios
  { title: "Cinema com pipoca grande",                 cost: 400,   icon: "popcorn",          category: "Passeios" },
  { title: "Trampolim/parque de diversão",             cost: 500,   icon: "ticket-01",        category: "Passeios" },
  { title: "Zoológico ou aquário",                     cost: 600,   icon: "ferris-wheel",     category: "Passeios" },
  { title: "Parque aquático",                          cost: 800,   icon: "ticket-01",        category: "Passeios" },
  { title: "Parque temático (viagem dia inteiro)",     cost: 2500,  icon: "ferris-wheel",     category: "Passeios" },
  { title: "Beto Carrero World",                       cost: 5000,  icon: "ferris-wheel",     category: "Passeios" },

  # Aspiracionais — brinquedos grandes
  { title: "LEGO médio",                               cost: 800,   icon: "cube",             category: "Brinquedos" },
  { title: "Patinete novo",                            cost: 1200,  icon: "scooter-02",       category: "Brinquedos" },
  { title: "LEGO grande",                              cost: 1500,  icon: "cube",             category: "Brinquedos" },
  { title: "Skate ou patins",                          cost: 1500,  icon: "rollerskate",      category: "Brinquedos" },
  { title: "Microscópio ou kit de ciência",            cost: 1500,  icon: "microscope",       category: "Brinquedos" },
  { title: "Instrumento musical (ukulele/teclado)",    cost: 2000,  icon: "music-note-01",    category: "Brinquedos" },
  { title: "Câmera digital infantil",                  cost: 2500,  icon: "camera-01",        category: "Brinquedos" },
  { title: "Bicicleta nova",                           cost: 3000,  icon: "bicycle",          category: "Brinquedos" },

  # Aspiracionais — tech
  { title: "Headphone gamer",                          cost: 4000,  icon: "headphones",       category: "Telinha" },
  { title: "Console Nintendo Switch Lite",             cost: 8000,  icon: "nintendo-switch",  category: "Telinha" },
  { title: "Tablet novo",                              cost: 8000,  icon: "tablet-01",        category: "Telinha" },
  { title: "Nintendo Switch novo",                     cost: 10000, icon: "nintendo-switch",  category: "Telinha" },
  { title: "Celular novo (quando idade permitir)",     cost: 12000, icon: "smart-phone-01",   category: "Telinha" },

  # Conquistas coletivas — semanais
  { title: "[Família] Sorvete depois do jantar",       cost: 120,   icon: "ice-cream-01",     category: "Docinhos" },
  { title: "[Família] Pizza no jantar de sexta",       cost: 150,   icon: "pizza-01",         category: "Experiências" },
  { title: "[Família] Café da manhã reforçado de domingo", cost: 150, icon: "coffee-01",      category: "Experiências" },
  { title: "[Família] Filme com pipoca em família",    cost: 180,   icon: "popcorn",          category: "Experiências" },
  { title: "[Família] Acampamento na sala",            cost: 250,   icon: "moon-01",          category: "Experiências" },

  # Conquistas coletivas — mensais
  { title: "[Família] Tarde de jogos só de jogos",     cost: 300,   icon: "puzzle",           category: "Experiências" },
  { title: "[Família] Cinema todo mundo junto",        cost: 400,   icon: "film-01",          category: "Passeios" },
  { title: "[Família] Restaurante em família",         cost: 500,   icon: "dish-01",          category: "Experiências" },
  { title: "[Família] Passeio em parque/lugar novo",   cost: 600,   icon: "ferris-wheel",     category: "Passeios" },
  { title: "[Família] Dia do 'sim'",                   cost: 800,   icon: "happy",            category: "Experiências" },

  # Conquistas coletivas — aspiracionais
  { title: "[Família] Final de semana fora",           cost: 3000,  icon: "ferris-wheel",     category: "Passeios" },
  { title: "[Família] Viagem pequena (2-3 dias)",      cost: 6000,  icon: "rocket",           category: "Passeios" },
  { title: "[Família] Disney / viagem grande",         cost: 20000, icon: "rocket",           category: "Passeios" }
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
puts "  Missions per kid: Lis=#{lis_missions.size}, Theo=#{theo_missions.size}, Laura=#{laura_missions.size}"
puts "  Total: #{family.global_tasks.count} missions, #{family.rewards.count} rewards, #{family.categories.count} categories"
