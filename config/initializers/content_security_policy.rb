# Be sure to restart your server when you modify this file.
#
# Application-wide content security policy.
# Inline styles are allowed because views set `style="..."` for dynamic
# tinting (mission cards, lens panels). Scripts are nonce-gated.

# Skip CSP in test — Capybara/Selenium inject helpers that need inline
# script execution outside the nonce flow, and CSP cannot meaningfully
# guard a non-production env. The test suite covers no XSS surface.
return if Rails.env.test?

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.frame_ancestors :none

    policy.img_src   :self, :https, :data, :blob
    policy.font_src  :self, :https, :data
    policy.media_src :self, :data

    policy.style_src  :self, :https, :unsafe_inline
    policy.script_src :self, :https

    # ActionCable + Turbo Streams (same-origin websocket).
    policy.connect_src :self, :https, :wss

    # Allow Vite dev server + Vite client HMR (eval + ws) only in development.
    # `ws:` is wide here because Docker port-forwarding maps Vite's internal
    # port (3036) to an arbitrary host port; the browser uses the host port.
    if Rails.env.development?
      policy.script_src(*policy.script_src, :unsafe_eval)
      policy.connect_src(*policy.connect_src, "ws:", "http:")
      policy.style_src(*policy.style_src, "http:")
    end

    if Rails.env.test?
      policy.script_src(*policy.script_src, :blob)
    end
  end

  # Nonce-gate inline scripts (Turbo + Stimulus tags pick this up via csp_meta_tag).
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
