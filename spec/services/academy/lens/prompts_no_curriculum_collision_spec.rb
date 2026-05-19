# frozen_string_literal: true

require "rails_helper"

# Guards against Gap #1 from the 2026-05-17 Lens v3 followups audit:
# when a prompt's hardcoded few-shot example uses a concept that is ALSO
# in the curriculum, the LLM tends to clone the example verbatim when
# the generation target happens to be that same concept.
#
# The fix: keep the hardcoded `# EXEMPLO DE REFERÊNCIA` example pinned
# to a neutral concept that is NOT one of the 45 curriculum concepts.
#
# This spec inspects each prompt template and asserts none of the
# curriculum concept names/slugs appear inside the hardcoded example
# header line.
RSpec.describe "Academy::Lens prompts vs curriculum collision" do
  PROMPTS_DIR = Rails.root.join("app/services/academy/lens/prompts")

  # Surface-level tokens we want to keep OUT of the `# EXEMPLO DE REFERÊNCIA`
  # hardcoded example headers. These were the original collision-prone ones
  # listed in the audit (Gap #1, 2026-05-17). Any new prompt example must
  # pick a topic that is NOT one of these curriculum-adjacent terms.
  FORBIDDEN_EXAMPLE_TOPICS = [
    "dopamina",
    "recompensa variável",
    "atenção plena",
    "honestidade radical",
    "palavra dada",
    "açúcar e fome de rebote"
  ].freeze

  Dir[PROMPTS_DIR.join("*.md.erb")].each do |path|
    name = File.basename(path)

    it "#{name} hardcoded example header avoids curriculum-adjacent topics" do
      contents = File.read(path)
      header_line = contents.lines.find do |l|
        l.include?("# EXEMPLO DE REFERÊNCIA")
      end

      expect(header_line).to be_present,
        "Expected '# EXEMPLO DE REFERÊNCIA' header in #{name}"

      FORBIDDEN_EXAMPLE_TOPICS.each do |topic|
        expect(header_line).not_to include(topic),
          "#{name} still uses '#{topic}' as hardcoded example concept — risk of few-shot cloning (audit Gap #1)"
      end
    end
  end
end
