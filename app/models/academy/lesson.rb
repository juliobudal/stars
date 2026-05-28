# frozen_string_literal: true

module Academy
  # One curated "pílula de conhecimento". Content lives in `payload` (jsonb) and
  # follows the mystery format: enigma → clues → revelation → check → hook.
  #
  # payload shape:
  #   {
  #     "clues":      ["...", "..."],          # 2..4 surprising micro-facts
  #     "revelation": "the central insight",   # required
  #     "check":      { "kind", "prompt", "options"[], "answer_index", "explanation" } | null,
  #     "hook":       "teaser for the next lesson"   # required
  #   }
  class Lesson < ApplicationRecord
    self.table_name = "academy_lessons"

    MIN_CLUES = 2
    MAX_CLUES = 4

    belongs_to :trail, class_name: "Academy::Trail", inverse_of: :lessons

    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
    validates :title, :enigma, :position, presence: true
    validate :payload_well_formed

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position) }

    def to_param = slug

    def clues = Array(payload["clues"])
    def revelation = payload["revelation"].to_s
    def hook = payload["hook"].to_s

    def check = payload["check"].is_a?(Hash) ? payload["check"] : nil
    def check? = check.present?

    private

    def payload_well_formed
      return errors.add(:payload, "must be a Hash") unless payload.is_a?(Hash)

      cl = Array(payload["clues"])
      errors.add(:payload, "needs #{MIN_CLUES}..#{MAX_CLUES} clues") unless cl.size.between?(MIN_CLUES, MAX_CLUES)
      errors.add(:payload, "revelation is required") if payload["revelation"].to_s.strip.empty?
      errors.add(:payload, "hook is required") if payload["hook"].to_s.strip.empty?

      c = payload["check"]
      return if c.nil?
      return errors.add(:payload, "check must be a Hash") unless c.is_a?(Hash)

      options = Array(c["options"])
      idx = c["answer_index"]
      errors.add(:payload, "check needs a prompt") if c["prompt"].to_s.strip.empty?
      errors.add(:payload, "check needs >= 2 options") if options.size < 2
      errors.add(:payload, "check answer_index out of range") unless idx.is_a?(Integer) && idx.between?(0, options.size - 1)
    end
  end
end
