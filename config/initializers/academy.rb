# frozen_string_literal: true

# Academy module config — kept here (not inside the module) so that adding
# new namespaced modules in the future follows the same Rails-idiomatic
# initializer convention. The module itself never reads ENV directly; it
# always goes through Academy.config.
Rails.application.config.to_prepare do
  next unless defined?(Academy)

  Academy.configure do |c|
    # Prefer encrypted credentials (`rails credentials:edit`); fall back to
    # ENV so dev/Docker workflows keep working without a credentials key.
    credentials_key = Rails.application.credentials.dig(:openrouter, :api_key)
    c.openrouter_api_key  = (credentials_key.presence || ENV["OPENROUTER_API_KEY"]).to_s
    c.openrouter_base_url = ENV.fetch("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    c.model               = ENV.fetch("ACADEMY_LLM_MODEL", "deepseek/deepseek-v4-flash")
    c.temperature         = ENV.fetch("ACADEMY_LLM_TEMPERATURE", "0.7").to_f
    # Generous cap — schemas + ERB templates limit actual output, so this is
    # an upper-bound safety net rather than a target. Output cost only
    # accrues on tokens actually emitted.
    c.max_tokens          = ENV.fetch("ACADEMY_LLM_MAX_TOKENS", "10000").to_i
    c.referer             = ENV.fetch("ACADEMY_LLM_REFERER", "https://littlestars.app")
    c.app_title           = ENV.fetch("ACADEMY_LLM_APP_TITLE", "LittleStars Academy")

    c.image_model         = ENV.fetch("ACADEMY_IMAGE_MODEL", "google/gemini-2.5-flash-image")
    c.image_size          = ENV.fetch("ACADEMY_IMAGE_SIZE", "1K")
    c.image_aspect_ratio  = ENV.fetch("ACADEMY_IMAGE_ASPECT_RATIO", "1:1")
  end
end
