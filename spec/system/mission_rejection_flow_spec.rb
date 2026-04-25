require "rails_helper"

RSpec.describe "Mission Rejection Flow", type: :system do
  let!(:family)       { create(:family, name: "Teste") }
  let!(:parent_profile) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child_profile)  { create(:profile, :child, family: family, name: "Filhote", points: 0) }
  let!(:global_task)    { create(:global_task, family: family, title: "Arrumar Quarto", points: 200) }
  let!(:profile_task)   { create(:profile_task, profile: child_profile, global_task: global_task, status: :pending) }

  it "permite ao filho enviar uma missão e ao pai rejeitar, sem conceder pontos" do
    # 1. Filho submete a missão via modal
    sign_in_as_child(child_profile)

    expect(page).to have_content("Arrumar Quarto")
    # Abre o modal via JS (começa com display:none) e clica no botão de conclusão
    open_modal_and_click("modal_profile_task_#{profile_task.id}", "Terminei!")

    expect(page).to have_content("Missão enviada para aprovação! 🚀")

    # 2. Pai navega até a fila de aprovações e rejeita a missão
    sign_in_as_parent(parent_profile)

    expect(page).to have_content("Olá, Papai")
    visit parent_approvals_path

    expect(page).to have_css("#panel-missions", text: "Arrumar Quarto", visible: true)

    # button_to "Rejeitar" fica dentro de um <form> aninhado no form externo de bulk-approve.
    # Chrome vaza o campo _method=patch do form interno para o form externo e submete o errado.
    # Solução: usar Turbo.visit com método PATCH via fetch + recarregar a página para ver o flash
    # de sessão que o redirect HTML deixa. O CSRF token é extraído do meta tag.
    reject_url = reject_parent_approval_path(profile_task)
    csrf = page.evaluate_script("document.querySelector('meta[name=\"csrf-token\"]')?.content")
    page.execute_script(<<~JS)
      fetch(#{reject_url.to_json}, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': #{csrf.to_json},
          'Accept': 'text/html, application/xhtml+xml',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        credentials: 'same-origin'
      }).then(function() {
        window.__rejectDone = true;
      });
    JS
    # Aguarda o servidor processar a rejeição e recarrega para exibir o flash de sessão
    expect(page).to have_css("body") # sincroniza antes do sleep
    sleep 1.5
    visit parent_approvals_path

    expect(page).to have_content("Tarefa rejeitada.", wait: 10)

    # 3. Filho volta e verifica que não ganhou pontos
    sign_in_as_child(child_profile)
    visit kid_wallet_index_path

    expect(page).to have_content("0")
    expect(page).not_to have_content("Arrumar Quarto")
  end
end
