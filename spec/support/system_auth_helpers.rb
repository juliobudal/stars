module SystemAuthHelpers
  # Parent: click "Pais" tab (hidden by JS), fill email+password form, submit.
  # Waits for the parent dashboard to confirm the session is established.
  def sign_in_as_parent(profile, password: "supersecret1234")
    visit root_path
    # Click the "Pais" tab button (Stimulus picker-tabs#switch reveals the parent panel)
    find("button[data-tab='parents']").click
    # Reveal the hidden parent panel directly so Capybara can fill in the form
    page.execute_script(<<~JS)
      var panel = document.querySelector('[data-picker-tabs-target="panel"][data-tab="parents"]');
      if (panel) { panel.hidden = false; panel.style.display = ''; }
    JS
    fill_in "email", with: profile.email
    fill_in "password", with: password
    click_button "Entrar"
    # Wait for navigation to parent dashboard to complete
    expect(page).to have_content("Olá, #{profile.name}", wait: 10)
  end

  # Kid: click the profile-picker card button that contains the kid's name.
  # Waits for the kid dashboard to confirm the session is established.
  def sign_in_as_child(profile)
    visit root_path
    find("button", text: profile.name).click
    # Wait for navigation to complete (kid dashboard shows profile name in greeting)
    expect(page).to have_content(profile.name, wait: 10)
  end

  # Open an inline modal by ID via JS and click a button inside it by text.
  # Uses JS for both steps because the modal starts with display:none and Capybara's
  # visibility checks are computed-style-aware even after a JS style change.
  def open_modal_and_click(modal_id, button_text)
    page.execute_script(<<~JS)
      var modal = document.getElementById('#{modal_id}');
      modal.style.display = 'flex';
      var btns = modal.querySelectorAll('button, input[type=submit]');
      for (var i = 0; i < btns.length; i++) {
        if (btns[i].textContent.trim().indexOf('#{button_text.gsub("'", "\\\\'")}') !== -1) {
          btns[i].click();
          break;
        }
      }
    JS
  end
end
