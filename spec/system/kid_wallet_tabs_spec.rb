require "rails_helper"

# Regression guard: the wallet tab strip (Ui::CategoryTabs) and its #panel-*
# regions are switched by a single "tabs" Stimulus controller on the wrapper.
# A previous version nested a second `data-controller="tabs"` inside the strip,
# which captured the click without seeing the sibling panels — aria-selected
# moved but the visible panel never changed. This locks the click→panel switch.
RSpec.describe "Carteira (Diário) — troca de abas", type: :system do
  let!(:family) { create(:family, name: "Família Abas") }
  let!(:child)  { create(:profile, :child, family: family, name: "Tico", points: 0) }

  it "troca o painel visível ao clicar numa aba" do
    sign_in_as_child(child)
    visit kid_wallet_index_path

    # Aba "Tudo" ativa por padrão → painel "Tudo" visível, demais ocultos.
    expect(page).to have_content("Nenhuma atividade ainda", wait: 10)
    expect(page).to have_no_content("Esperando pai/mãe")

    # Clicar em "Esperando" deve revelar o painel pending e ocultar o painel "Tudo".
    click_button "Esperando"

    expect(page).to have_content("Esperando pai/mãe", wait: 10)
    expect(page).to have_no_content("Nenhuma atividade ainda")
  end
end
