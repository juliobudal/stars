# frozen_string_literal: true

# Top-level namespace for the Academy learning module.
#
# This module is intentionally isolated from the host LittleStars app:
# - All ActiveRecord models live under Academy:: and target academy_* tables.
# - No foreign keys point into the host (learners are referenced by id only).
# - The host communicates with Academy through Academy::Learner adapter and
#   Academy::* service objects. The reverse direction is forbidden.
#
# To add a new module (e.g. Journal, Reading), mirror this skeleton:
#   * app/models/<module>.rb with a similar `Config` + `Learner` boundary
#   * app/models/<module>/ for ActiveRecord models targeting <module>_* tables
#   * config/initializers/<module>.rb that reads ENV and calls `.configure`
#   * app/controllers/{kid,parent}/<module>/ for HTTP entry points
module Academy
  Config = Struct.new(
    :openrouter_api_key,
    :openrouter_base_url,
    :model,
    :temperature,
    :max_tokens,
    :referer,
    :app_title,
    :judge_model,
    :judge_temperature,
    :judge_max_tokens,
    :judge_reasoning_effort,
    :judge_enabled,
    :judge_max_revision_cycles,
    keyword_init: true
  )

  class << self
    def config
      @config ||= Config.new(
        openrouter_api_key: "",
        openrouter_base_url: "https://openrouter.ai/api/v1",
        model: "deepseek/deepseek-v4-flash",
        temperature: 0.7,
        max_tokens: 10000,
        referer: "https://littlestars.app",
        app_title: "LittleStars Academy",
        judge_model: "openai/gpt-5-nano",
        judge_temperature: 0.0,
        judge_max_tokens: 4000,
        judge_reasoning_effort: "minimal",
        judge_enabled: true,
        judge_max_revision_cycles: 1
      )
    end

    def configure
      yield(config)
    end

    def configured?
      config.openrouter_api_key.to_s.length > 8
    end
  end
end
