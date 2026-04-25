module SystemAuthHelpers
  def sign_in_family(family)
    visit new_family_session_path
    expect(page).to have_field("Email da família", wait: 5)
    fill_in "Email da família", with: family.email
    fill_in "Senha", with: "supersecret1234"
    click_on "Entrar"
  end

  def sign_in_profile(profile, pin: "1234")
    # Reset session so we always start clean: required when switching between
    # profiles (e.g. kid → parent in the same flow). Capybara's `reset!` clears
    # cookies and session storage for the test app.
    Capybara.current_session.reset!
    sign_in_family(profile.family)
    expect(page).to have_current_path(new_profile_session_path, wait: 5)
    click_on profile.name
    # Wait for the turbo-frame PIN modal to render before tapping keys.
    expect(page).to have_css("button.pin-key", wait: 5)
    fill_pin(pin)
    # Wait for the post-PIN redirect to complete before letting tests proceed.
    target_path = profile.parent? ? parent_root_path : kid_root_path
    expect(page).to have_current_path(target_path, ignore_query: true, wait: 10)
  end

  def fill_pin(pin)
    pin.chars.each do |digit|
      find("button.pin-key", text: digit, match: :first).click
    end
  end

  # Backwards-compatible aliases used by existing system specs.
  def sign_in_as(profile, pin: "1234")
    sign_in_profile(profile, pin: pin)
  end

  def sign_in_as_parent(profile, pin: "1234")
    sign_in_profile(profile, pin: pin)
  end

  def sign_in_as_child(profile, pin: "1234")
    sign_in_profile(profile, pin: pin)
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

RSpec.configure do |config|
  config.include SystemAuthHelpers, type: :system
end
