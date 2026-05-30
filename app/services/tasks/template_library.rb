# frozen_string_literal: true

module Tasks
  # Curated starter missions parents can add in one click from the mission
  # library (/parent/global_tasks/library). Pure data — no persistence here;
  # Parent::GlobalTasksController#add_from_template builds GlobalTasks from
  # the selected keys.
  module TemplateLibrary
    TEMPLATES = [
      { key: "arrumar_cama",       title: "Arrumar a cama",            icon: "bed",     category: "rotina", frequency: "daily",  points: 5,  description: "Deixar a cama arrumada ao acordar." },
      { key: "escovar_dentes",     title: "Escovar os dentes",         icon: "brush",   category: "saude",  frequency: "daily",  points: 5,  description: "Escovar os dentes pela manhã e à noite." },
      { key: "licao_casa",         title: "Fazer a lição de casa",     icon: "book",    category: "escola", frequency: "daily",  points: 10, description: "Concluir as tarefas da escola." },
      { key: "ler_15min",          title: "Ler por 15 minutos",        icon: "bookOpen", category: "escola", frequency: "daily", points: 10, description: "Ler um livro por pelo menos 15 minutos." },
      { key: "guardar_brinquedos", title: "Guardar os brinquedos",     icon: "blocks",  category: "casa",   frequency: "daily",  points: 5,  description: "Organizar os brinquedos depois de brincar." },
      { key: "ajudar_cozinha",     title: "Ajudar na cozinha",         icon: "dish",    category: "casa",   frequency: "weekly", points: 15, days_of_week: [ "6" ], description: "Ajudar a preparar ou arrumar a mesa." },
      { key: "regar_plantas",      title: "Regar as plantas",          icon: "drop",    category: "casa",   frequency: "daily",  points: 5,  description: "Cuidar das plantas da casa." },
      { key: "cuidar_pet",         title: "Cuidar do pet",             icon: "paw",     category: "rotina", frequency: "daily",  points: 5,  description: "Dar comida e água ao animalzinho." },
      { key: "organizar_quarto",   title: "Organizar o quarto",        icon: "home",    category: "casa",   frequency: "weekly", points: 20, days_of_week: [ "6" ], description: "Deixar o quarto limpo e organizado." },
      { key: "exercicio",          title: "Fazer exercício",           icon: "muscle",  category: "saude",  frequency: "daily",  points: 10, description: "Brincar ao ar livre ou se exercitar." },
      { key: "gratidao",           title: "Momento de gratidão",       icon: "sun",     category: "rotina", frequency: "daily",  points: 5,  description: "Agradecer e refletir sobre o dia." },
      { key: "tomar_banho",        title: "Tomar banho sozinho(a)",    icon: "drop",    category: "rotina", frequency: "daily",  points: 5,  description: "Cuidar da própria higiene." }
    ].freeze

    extend CuratedTemplates

    def self.attributes_for(key)
      tpl = find(key)
      return nil unless tpl

      tpl.except(:key)
    end
  end
end
