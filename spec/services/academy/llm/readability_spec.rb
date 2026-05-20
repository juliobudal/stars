# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Llm::Readability do
  describe ".score" do
    it "is high for short, simple sentences" do
      text = "O céu é azul. A água é fria. O sol esquenta."
      expect(described_class.score(text)).to be >= 75
    end

    it "is low for long, vocab-heavy adult prose" do
      text = "A heurística de disponibilidade constitui um viés cognitivo que enviesa decisões em direção à evidência mais facilmente recuperada na memória."
      expect(described_class.score(text)).to be < 30
    end

    it "returns 0 for empty input" do
      expect(described_class.score("")).to eq(0.0)
      expect(described_class.score("   ")).to eq(0.0)
    end

    it "handles a single short sentence" do
      expect(described_class.score("Olha o gato.")).to be > 60
    end
  end

  describe ".kid_friendly?" do
    it "true at default floor for kid-facing copy" do
      expect(described_class.kid_friendly?("O ferro afia o ferro. Um amigo afia o outro.")).to be(true)
    end

    it "false for dense adult prose" do
      text = "Considerações epistemológicas acerca da natureza falseável das hipóteses configuram o cerne do método científico moderno."
      expect(described_class.kid_friendly?(text)).to be(false)
    end
  end

  describe ".analyze" do
    it "classifies into ok/warn/block tiers" do
      ok    = described_class.analyze("O sol nasce. O dia começa.")
      warn  = described_class.analyze("A pílula entrega uma ideia útil. Ela cabe num dia normal de aula.")
      block = described_class.analyze("A consolidação mnemônica processada pelo hipocampo durante o sono REM otimiza a recuperação subsequente.")

      expect(ok.tier).to eq(:ok)
      expect(warn.tier).to be_in(%i[ok warn])
      expect(block.tier).to eq(:block)
    end

    it "reports word + sentence counts" do
      r = described_class.analyze("Um. Dois três. Quatro cinco seis.")
      expect(r.sentences).to eq(3)
      expect(r.words).to eq(6)
    end
  end
end
