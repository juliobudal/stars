require "rails_helper"

RSpec.describe "Parent Management Flow", type: :system do
  let!(:family) { create(:family, name: "Família Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Mamãe") }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Mamãe", wait: 10)
  end

  # Substitui o Turbo confirm customizado (usa <dialog>) por uma função que resolve
  # automaticamente com true, evitando a necessidade de interagir com o dialog HTML.
  def auto_accept_turbo_confirm
    page.execute_script(<<~JS)
      if (window.Turbo) {
        Turbo.config.forms.confirm = function(_msg) { return Promise.resolve(true); };
      }
    JS
  end

  # ─────────────────────────────────────────────
  # 1. Editar missão global
  # ─────────────────────────────────────────────
  describe "editar missão global" do
    let!(:task) { create(:global_task, family: family, title: "Lavar a louça", points: 30) }

    it "atualiza o título e exibe flash de confirmação" do
      # Navega diretamente para a página de edição (o turbo-frame do index usa CSS
      # overflow:hidden que pode ocultar o título para o Capybara)
      visit edit_parent_global_task_path(task)
      expect(page).to have_content("Salvar Missão", wait: 10)

      fill_in "Título", with: "Varrer o quintal"
      click_on "Salvar Missão"

      expect(page).to have_content("Tarefa atualizada com sucesso.", wait: 10)
      # O index é redirecionado após salvar; verifica que o título mudou no banco
      expect(task.reload.title).to eq("Varrer o quintal")
    end
  end

  # ─────────────────────────────────────────────
  # 2. Toggle ativo/inativo de missão global
  # ─────────────────────────────────────────────
  describe "toggle ativo de missão global" do
    let!(:task) { create(:global_task, family: family, title: "Dormir cedo", points: 20, active: true) }

    it "alterna o estado active da missão no banco" do
      visit parent_global_tasks_path
      # Aguarda o turbo-frame da missão estar presente no DOM
      expect(page).to have_selector("#mission_row_#{task.id}", wait: 10)

      # Clica no botão de toggle — aria-label "Desativar missão" quando active: true
      within("#mission_row_#{task.id}") do
        find("button[aria-label='Desativar missão']").click
      end

      # Aguarda a resposta Turbo Stream; o botão deve mudar para "Ativar missão"
      within("#mission_row_#{task.id}") do
        expect(page).to have_selector("button[aria-label='Ativar missão']", wait: 10)
      end

      expect(task.reload.active).to be false
    end
  end

  # ─────────────────────────────────────────────
  # 3. Excluir recompensa
  # ─────────────────────────────────────────────
  describe "excluir recompensa" do
    let!(:reward) { create(:reward, family: family, title: "Sorvete", cost: 50) }

    it "remove a recompensa do banco e exibe flash" do
      visit parent_rewards_path
      expect(page).to have_content("Sorvete", wait: 10)

      # O app usa um <dialog> customizado via Turbo.config.forms.confirm (não alert nativo).
      # Substituímos por uma função que auto-aceita para que o Capybara não precise
      # interagir com o dialog HTML.
      auto_accept_turbo_confirm

      find("button[data-turbo-confirm]").click

      expect(page).to have_content("Recompensa removida.", wait: 10)
      expect(page).not_to have_content("Sorvete")
      expect(Reward.exists?(reward.id)).to be false
    end
  end

  # ─────────────────────────────────────────────
  # 4. Editar perfil de filho
  # ─────────────────────────────────────────────
  describe "editar perfil de filho" do
    let!(:kid) { create(:profile, :child, family: family, name: "Binho") }

    it "atualiza o nome do filho e exibe flash de confirmação" do
      visit edit_parent_profile_path(kid)
      expect(page).to have_content("Salvar Perfil", wait: 10)

      fill_in "Nome", with: "Bernardinho"
      click_on "Salvar Perfil"

      expect(page).to have_content("Filho atualizado com sucesso!", wait: 10)
      expect(kid.reload.name).to eq("Bernardinho")
    end
  end

  # ─────────────────────────────────────────────
  # 5. Atualizar configurações da família
  # ─────────────────────────────────────────────
  describe "atualizar configurações" do
    it "persiste a alteração de fuso horário e exibe flash" do
      visit parent_settings_path
      expect(page).to have_content("Configurações", wait: 10)

      # Altera o fuso horário — campo select com name="family[timezone]"
      select "New York (GMT-4)", from: "family[timezone]"
      click_on "Salvar alterações"

      expect(page).to have_content("Salvo", wait: 10)
      expect(family.reload.timezone).to eq("America/New_York")
    end
  end
end
