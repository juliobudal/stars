require "rails_helper"

RSpec.describe "Activity Log e Saldo", type: :system do
  # ─── Cenário 1: Extrato completo após ciclo earn + redeem ───────────────────
  describe "extrato do pai após ciclo completo de missão e resgate" do
    let!(:family)       { create(:family, name: "Família Teste") }
    let!(:parent)       { create(:profile, :parent, family: family, name: "Papai") }
    let!(:child)        { create(:profile, :child,  family: family, name: "Filhote", points: 0) }
    let!(:global_task)  { create(:global_task, family: family, title: "Lavar a Louça", points: 200) }
    let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }
    let!(:reward)       { create(:reward, family: family, title: "Sorvete Duplo", cost: 100) }

    it "mostra entradas de ganho e resgate no extrato" do
      # 1. Filho acessa o dashboard e submete a missão via modal
      sign_in_as_child(child)
      expect(page).to have_content("Lavar a Louça", wait: 10)
      open_modal_and_click("modal_profile_task_#{profile_task.id}", "Terminei!")
      expect(page).to have_content("Missão enviada para aprovação!", wait: 10)

      # 2. Pai aprova a missão → gera ActivityLog earn
      sign_in_as_parent(parent)
      visit parent_approvals_path
      expect(page).to have_content("Lavar a Louça", wait: 10)
      click_on "Aprovar"
      expect(page).to have_content(/tarefa aprovada com sucesso!/i, wait: 10)

      # 3. Filho resgata a recompensa via modal → gera ActivityLog redeem
      sign_in_as_child(child)
      visit kid_rewards_path
      expect(page).to have_content("Sorvete Duplo", wait: 10)
      open_modal_and_click("modal_reward_#{reward.id}", "Sim, quero!")
      expect(page).to have_content("Resgate solicitado!", wait: 10)

      # 4. Pai aprova o resgate (revela painel via JS pois tabs_controller não controla painéis irmãos)
      sign_in_as_parent(parent)
      visit parent_approvals_path
      page.execute_script(<<~JS)
        var panel = document.getElementById('panel-rewards');
        if (panel) { panel.style.display = 'flex'; panel.style.flexDirection = 'column'; }
      JS
      expect(page).to have_css("#panel-rewards", text: "Sorvete Duplo", visible: true)
      within("#panel-rewards") do
        find("button", text: /entregue/i).click
      end
      expect(page).to have_content(/resgate aprovado!/i, wait: 10)

      # 5. Verifica o extrato: título da missão e da recompensa, pontos +200 e −100
      visit parent_activity_logs_path

      # Título da missão no extrato (ApproveService usa "Missão Concluída: <title>")
      expect(page).to have_content("Missão Concluída: Lavar a Louça", wait: 10)

      # Título da recompensa no extrato (RedeemService usa "Solicitado: <title>")
      expect(page).to have_content("Solicitado: Sorvete Duplo")

      # Na view: earn → '+' + points; redeem → '−' + points.abs
      expect(page).to have_content("+200")
      expect(page).to have_content("−100")
    end
  end

  # ─── Cenário 2: Filho não consegue resgatar com saldo insuficiente ──────────
  describe "saldo insuficiente ao tentar resgatar recompensa" do
    let!(:family)  { create(:family, name: "Família Pobre") }
    let!(:child)   { create(:profile, :child, family: family, name: "Filhote", points: 50) }
    let!(:reward)  { create(:reward, family: family, title: "Videogame", cost: 200) }

    it "exibe alerta e não altera o saldo nem cria resgate" do
      sign_in_as_child(child)
      visit kid_rewards_path
      expect(page).to have_content("Videogame", wait: 10)

      # A UI desabilita o botão quando saldo insuficiente; testa a proteção backend
      # submetendo um form HTML diretamente (sem Turbo), recebe redirect + flash
      page.execute_script(<<~JS)
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = '#{redeem_kid_reward_path(reward)}';
        form.style.display = 'none';
        document.body.appendChild(form);
        form.submit();
      JS

      expect(page).to have_content(/estrelas suficientes|saldo insuficiente/i, wait: 10)

      # Saldo e contagem de resgates permanecem inalterados
      expect(child.reload.points).to eq(50)
      expect(Redemption.count).to eq(0)
    end
  end
end
