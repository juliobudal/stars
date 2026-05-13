require "rails_helper"

RSpec.describe "Motion accessibility", type: :system, js: true do
  let!(:family) { create(:family) }
  let!(:child) { create(:profile, :child, family: family, name: "Lia") }
  let!(:global_task) { create(:global_task, family: family, title: "Lavar Louça", points: 100) }
  let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }

  before do
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    sign_in_as_child(child)
  end

  it "honors prefers-reduced-motion: no animations or transitions run on the kid dashboard" do
    visit kid_root_path
    expect(page).to have_content("Lavar Louça")

    offenders = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('*'))
        .filter(el => {
          const cs = getComputedStyle(el);
          const dur = parseFloat(cs.animationDuration) || 0;
          const tdur = parseFloat(cs.transitionDuration) || 0;
          return (dur > 0 || tdur > 0) && cs.animationName !== 'none';
        })
        .slice(0, 5)
        .map(el => el.tagName + '.' + el.className);
    JS

    expect(offenders).to be_empty, "Expected no animated elements under reduced motion, found: #{offenders.inspect}"
  end
end
