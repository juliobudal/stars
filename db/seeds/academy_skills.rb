# frozen_string_literal: true

# Academy v2 Phase 7+8 — Skills catalog, mission tagging, secrets catalog.
# Idempotent. Loaded at the bottom of seeds/academy.rb after the concept
# graph so all v2 missions exist when we tag them.

SKILLS_CATALOG = [
  { slug: "disciplina",      name: "Disciplina",       short_label: "Disciplina",    icon: "target",   position: 1 },
  { slug: "curiosidade",     name: "Curiosidade",      short_label: "Curiosidade",   icon: "sparkle",  position: 2 },
  { slug: "autonomia",       name: "Autonomia",        short_label: "Autonomia",     icon: "compass",  position: 3 },
  { slug: "foco",            name: "Foco",             short_label: "Foco",          icon: "target",   position: 4 },
  { slug: "saude",           name: "Saúde",            short_label: "Saúde",         icon: "muscle",   position: 5 },
  { slug: "comunicacao",     name: "Comunicação",      short_label: "Conversa",      icon: "users",    position: 6 },
  { slug: "logica",          name: "Lógica",           short_label: "Lógica",        icon: "puzzle",   position: 7 },
  { slug: "responsabilidade", name: "Responsabilidade", short_label: "Responsabilidade", icon: "check", position: 8 },
  { slug: "criatividade",    name: "Criatividade",     short_label: "Criatividade",  icon: "magic",    position: 9 }
].freeze

# mission_slug => [primary_skill_slug, secondary_skill_slug]
# Primary gets weight 2, secondary weight 1.
MISSION_SKILLS = {
  # Mente Forte / atencao
  "celular-difícil-parar"      => %w[foco disciplina],
  "notificacoes-custam-23-min" => %w[foco disciplina],
  "foco-profundo-25min"        => %w[foco disciplina],
  "habito-2-minutos"           => %w[disciplina autonomia],
  # Mente Forte / vieses
  "vies-confirmacao"           => %w[logica autonomia],
  "memoria-falsa"              => %w[logica curiosidade],
  "pensar-devagar"             => %w[logica foco],
  # Corpo & Saúde / energia
  "acucar-engana-cerebro"      => %w[saude autonomia],
  "noite-ruim-apaga-semana"    => %w[saude disciplina],
  "10-min-movimento"           => %w[saude disciplina],
  "agua-confunde-fome"         => %w[saude curiosidade],
  # Corpo & Saúde / telas
  "tela-pre-sono"              => %w[saude disciplina],
  "scroll-infinito-mente"      => %w[foco autonomia],
  "atencao-sem-tela"           => %w[criatividade foco],
  # Dinheiro
  "impulso-perigoso"           => %w[disciplina responsabilidade],
  "querer-precisar"            => %w[autonomia responsabilidade],
  "guardar-mais-que-gastar"    => %w[disciplina autonomia],
  "dinheiro-vira-dinheiro"     => %w[logica curiosidade],
  # Caráter
  "mentiras-pequenas-custam"   => %w[responsabilidade disciplina],
  "compromisso-cumprido"       => %w[responsabilidade disciplina],
  "gratidao-muda-vista"        => %w[responsabilidade foco],
  "coragem-nao-ausencia-medo"  => %w[autonomia disciplina],
  # Tecnologia & Criação
  "como-app-funciona"          => %w[curiosidade logica],
  "como-ia-decide"             => %w[logica autonomia],
  "como-internet-conhece-voce" => %w[autonomia logica],
  "criador-vs-consumidor"      => %w[criatividade autonomia],
  # Resolver Problemas
  "quebrar-problema"           => %w[logica autonomia],
  "erro-dado"                  => %w[autonomia criatividade],
  "priorizar-pareto"           => %w[logica foco],
  "5-porques"                  => %w[logica curiosidade],
  # Vida & Sociedade
  "escutar-de-verdade"         => %w[comunicacao responsabilidade],
  "manipulacao-marcas"         => %w[autonomia logica],
  "silencio-constroi-confianca" => %w[comunicacao foco],
  "feedback-que-serve"         => %w[comunicacao responsabilidade]
}.freeze

SECRETS_CATALOG = [
  {
    slug: "explorador-da-mente",
    title: "Segredo: O caminho da Mente",
    teaser: "Algo escondido aparece quando você junta 3 cartas de Mente Forte…",
    kind: :cards_in_subject,
    rule: { "subject_slug" => "mente-forte", "threshold" => 3 },
    position: 1
  },
  {
    slug: "explorador-do-corpo",
    title: "Segredo: O caminho do Corpo",
    teaser: "3 cartas de Corpo & Saúde liberam algo só pra quem chegou aqui.",
    kind: :cards_in_subject,
    rule: { "subject_slug" => "corpo-saude", "threshold" => 3 },
    position: 2
  },
  {
    slug: "construtor-disciplinado",
    title: "Segredo: O selo da palavra",
    teaser: "5 desafios reportados com honestidade revelam algo raro.",
    kind: :challenge_ratio,
    rule: { "min_reports" => 5, "min_ratio" => 0.5 },
    position: 3
  },
  {
    slug: "colecionador",
    title: "Segredo: O atlas das ideias",
    teaser: "10 cartas — qualquer área — destravam o atlas das ideias.",
    kind: :cards_total,
    rule: { "threshold" => 10 },
    position: 4
  }
].freeze

ActiveRecord::Base.transaction do
  SKILLS_CATALOG.each do |attrs|
    record = ::Academy::Skill.find_or_initialize_by(slug: attrs[:slug])
    record.assign_attributes(attrs)
    record.save!
  end

  skills_by_slug = ::Academy::Skill.all.index_by(&:slug)

  MISSION_SKILLS.each do |mission_slug, skill_slugs|
    mission = ::Academy::Mission.find_by(slug: mission_slug)
    next unless mission

    desired_skill_ids = skill_slugs.map { |s| skills_by_slug[s]&.id }.compact
    next if desired_skill_ids.empty?

    desired_skill_ids.each_with_index do |skill_id, idx|
      ac = ::Academy::AulaSkill.find_or_initialize_by(mission_id: mission.id, skill_id: skill_id)
      ac.weight = (idx.zero? ? 2 : 1)
      ac.save!
    end

    ::Academy::AulaSkill
      .where(mission_id: mission.id)
      .where.not(skill_id: desired_skill_ids)
      .delete_all
  end

  SECRETS_CATALOG.each do |attrs|
    record = ::Academy::Secret.find_or_initialize_by(slug: attrs[:slug])
    record.assign_attributes(
      title: attrs[:title],
      teaser: attrs[:teaser],
      kind: ::Academy::Secret.kinds.fetch(attrs[:kind].to_s),
      rule: attrs[:rule],
      position: attrs[:position],
      active: true
    )
    record.save!
  end
end

puts "✓ Academy skills + secrets seeded: " \
     "#{::Academy::Skill.count} skills · " \
     "#{::Academy::AulaSkill.count} tags aula↔skill · " \
     "#{::Academy::Secret.active.count} segredos."
