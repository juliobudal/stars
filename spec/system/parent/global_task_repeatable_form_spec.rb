require "rails_helper"

RSpec.describe "Repeatable mission form", type: :system do
  let!(:family) { create(:family) }
  let!(:parent) { create(:profile, :parent, family: family, name: "Mamãe") }

  before { sign_in_as_parent(parent) }

  it "hides the cap input by default and reveals it when the toggle is enabled", js: true do
    visit new_parent_global_task_path
    expect(page).to have_field("Título da missão", wait: 10)

    expect(page).to have_css('[data-repeatable-target="field"].hidden', visible: :all)

    find('[data-repeatable-target="toggle"]').click

    expect(page).not_to have_css('[data-repeatable-target="field"].hidden', visible: :all)
    expect(find('[data-repeatable-target="input"]').value).to eq("3")
  end

  it "disables the toggle and forces max=1 when frequency is set to 'once'", js: true do
    visit new_parent_global_task_path
    expect(page).to have_field("Título da missão", wait: 10)

    find("label", text: "Única").click
    expect(find('[data-repeatable-target="toggle"]')).to be_disabled
    expect(find('[data-repeatable-target="input"]', visible: :all).value).to eq("1")
  end

  it "persists max_completions_per_period when the form is submitted", js: true do
    visit new_parent_global_task_path
    expect(page).to have_field("Título da missão", wait: 10)

    fill_in "Título da missão", with: "Escovar dentes"
    find('[data-repeatable-target="toggle"]').click
    fill_in "global_task[max_completions_per_period]", with: 3
    click_on "Salvar missão"

    expect(page).to have_content("Tarefa criada com sucesso", wait: 10)
    expect(GlobalTask.find_by(title: "Escovar dentes").max_completions_per_period).to eq(3)
  end
end
