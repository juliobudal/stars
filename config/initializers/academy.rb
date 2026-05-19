# frozen_string_literal: true

# Academy module config — kept here (not inside the module) so that adding
# new namespaced modules in the future follows the same Rails-idiomatic
# initializer convention. The module itself never reads ENV directly; it
# always goes through Academy.config.
Rails.application.config.to_prepare do
  next unless defined?(Academy)

  Academy.configure do |c|
    c.openrouter_api_key  = ENV["OPENROUTER_API_KEY"].to_s
    c.openrouter_base_url = ENV.fetch("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    c.model               = ENV.fetch("ACADEMY_LLM_MODEL", "deepseek/deepseek-v4-flash")
    c.temperature         = ENV.fetch("ACADEMY_LLM_TEMPERATURE", "0.7").to_f
    # Generous cap — schemas + ERB templates limit actual output, so this is
    # an upper-bound safety net rather than a target. Output cost only
    # accrues on tokens actually emitted.
    c.max_tokens          = ENV.fetch("ACADEMY_LLM_MAX_TOKENS", "10000").to_i
    c.referer             = ENV.fetch("ACADEMY_LLM_REFERER", "https://littlestars.app")
    c.app_title           = ENV.fetch("ACADEMY_LLM_APP_TITLE", "LittleStars Academy")

    # Judge model — cheap + deterministic. Used by Academy::Llm::Judge
    # (transfer detection today; lens output evals in v5 Phase 8).
    # gpt-5-nano: OpenAI's cheapest reasoning model ($0.05/1M in, $0.40/1M out).
    # NOTE on reasoning_effort: gpt-5-nano is "pre-5.1" and does NOT accept
    # `none` (would 400). Minimum allowed is `minimal`, which is what we use.
    # To truly disable reasoning, migrate the model to `openai/gpt-5.1-nano`
    # — only the 5.1 line supports `none`.
    #
    # 4000 max_tokens gives the reasoning trace breathing room while keeping
    # cost-per-judgment bounded (~$0.0016 worst case). Temperature is mostly
    # ignored by reasoning models; kept for non-reasoning fallback judges.
    c.judge_model         = ENV.fetch("ACADEMY_JUDGE_MODEL", "openai/gpt-5-nano")
    c.judge_temperature   = ENV.fetch("ACADEMY_JUDGE_TEMPERATURE", "0.0").to_f
    c.judge_max_tokens    = ENV.fetch("ACADEMY_JUDGE_MAX_TOKENS", "4000").to_i
    c.judge_reasoning_effort = ENV.fetch("ACADEMY_JUDGE_REASONING_EFFORT", "minimal")
  end
end
