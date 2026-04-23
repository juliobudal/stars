require "rails_helper"

RSpec.describe "I18n locale configuration" do
  it "has pt-BR as default locale" do
    expect(I18n.default_locale).to eq(:"pt-BR")
  end

  it "includes :en and :'pt-BR' in available locales" do
    expect(I18n.available_locales).to include(:en, :"pt-BR")
  end

  describe "smoke key common.save" do
    it "returns 'Salvar' in pt-BR" do
      I18n.with_locale(:"pt-BR") do
        expect(I18n.t("common.save")).to eq("Salvar")
      end
    end

    it "returns 'Save' in en" do
      I18n.with_locale(:en) do
        expect(I18n.t("common.save")).to eq("Save")
      end
    end
  end

  describe "pt-BR translations" do
    around { |ex| I18n.with_locale(:"pt-BR") { ex.run } }

    it "translates common.cancel" do
      expect(I18n.t("common.cancel")).to eq("Cancelar")
    end

    it "translates flashes.saved" do
      expect(I18n.t("flashes.saved")).to eq("Salvo com sucesso.")
    end

    it "translates parent.nav.home" do
      expect(I18n.t("parent.nav.home")).to eq("Início")
    end
  end
end
