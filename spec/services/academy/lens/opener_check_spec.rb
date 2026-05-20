# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::OpenerCheck do
  describe ".has_hook?" do
    it "accepts the classic 'você sabia que' opener (wonder-hook rehabilitated)" do
      expect(described_class.has_hook?("Você sabia que o coração bate 100 mil vezes por dia?")).to be(true)
    end

    it "accepts a concrete short sentence" do
      expect(described_class.has_hook?("O gelo flutua. Veja por quê.")).to be(true)
    end

    it "accepts 'olha só' and 'repara nisso'" do
      expect(described_class.has_hook?("Olha só esse fato curioso. Você nunca tinha pensado.")).to be(true)
      expect(described_class.has_hook?("Repara nisso: água quebra pedra.")).to be(true)
    end

    it "rejects a long, abstract opener with no hook pattern" do
      expect(described_class.has_hook?(
        "A complexidade dos sistemas neurais e suas interações químicas constituem um tema central da neurociência cognitiva contemporânea."
      )).to be(false)
    end

    it "returns false for blank input" do
      expect(described_class.has_hook?("")).to be(false)
      expect(described_class.has_hook?(nil)).to be(false)
    end
  end

  describe ".first_sentence" do
    it "splits on terminal punctuation" do
      expect(described_class.first_sentence("Um. Dois. Três.")).to eq("Um.")
    end

    it "handles single sentence without trailing punctuation" do
      expect(described_class.first_sentence("Frase só")).to eq("Frase só")
    end
  end
end
