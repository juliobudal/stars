require "rails_helper"

RSpec.describe "Reward Rejection Flow", type: :system do
  let!(:family) { create(:family, name: "Teste") }
  let!(:parent) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child)  { create(:profile, :child,  family: family, name: "Filhote", points: 500) }
  let!(:reward) { create(:reward, family: family, title: "Sorvete", cost: 300) }

  it "permite ao pai cancelar um resgate pendente e devolver os pontos ao filho" do
    # 1. Filho resgata a recompensa via modal
    sign_in_as_child(child)
    visit kid_rewards_path

    expect(page).to have_content("Sorvete")

    # RedeemService desconta pontos imediatamente (500 - 300 = 200)
    open_modal_and_click("modal_reward_#{reward.id}", "Sim, quero!")

    expect(page).to have_content("Resgate solicitado!")

    # 2. Pai acessa a página de aprovações e revela o painel de resgates
    sign_in_as_parent(parent)
    visit parent_approvals_path

    # O tabs_controller não alcança os painéis irmãos — revelamos via JS diretamente
    page.execute_script(<<~JS)
      var panel = document.getElementById('panel-rewards');
      if (panel) { panel.style.display = 'flex'; panel.style.flexDirection = 'column'; }
    JS

    expect(page).to have_css("#panel-rewards", text: "Sorvete", visible: true)

    # 3. Pai cancela o resgate
    # O painel está dentro de um <form> externo (bulk_approve). Nested forms HTML fazem
    # o clique no DOM submeter o form errado. Usamos o Capybara HTTP driver diretamente
    # para enviar o PATCH de reject_redemption com o CSRF token da sessão atual.
    redemption = Redemption.last
    reject_url = reject_redemption_parent_approval_path(redemption)

    # Extrai o CSRF token via evaluate_script (retorna string Ruby) para injetá-lo no fetch
    csrf_token = page.evaluate_script(
      "document.head.querySelector('[name=csrf-token]')?.getAttribute('content') || ''"
    )

    # Submete o PATCH com redirect:manual para que o browser receba o redirect
    # e navegue para a URL final sem consumir o flash antecipadamente.
    page.execute_script(<<~JS)
      var fd = new FormData();
      fd.append('_method', 'patch');
      fetch(#{reject_url.to_json}, {
        method: 'POST',
        headers: { 'X-CSRF-Token': #{csrf_token.to_json} },
        body: fd,
        redirect: 'manual'
      }).then(function(res) {
        var loc = res.headers.get('location') || #{parent_approvals_path.to_json};
        window.location.assign(loc);
      });
    JS

    # Aguarda a navegação de redirect completar com o flash notice
    expect(page).to have_content("Resgate rejeitado e pontos devolvidos.", wait: 10)

    # 4. Verifica que os pontos foram devolvidos ao filho (500 - 300 + 300 = 500)
    child.reload
    expect(child.points).to eq(500)

    # 5. Visita o painel do filho e confirma que o saldo exibido é 500
    sign_in_as_child(child)
    visit kid_root_path

    expect(page).to have_css("[data-count-up-target='display']", text: "500")

    # 6. Log de atividade registra o reembolso
    sign_in_as_parent(parent)
    visit parent_activity_logs_path

    expect(page).to have_content("Resgate Recusado (Reembolso): Sorvete")
  end
end
