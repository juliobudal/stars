# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_concepts
#
#  id                                                                                    :bigint           not null, primary key
#  active                                                                                :boolean          default(TRUE), not null
#  category(cognitivo | cientifico | social | financeiro | saude | virtude | tecnologia) :string           not null
#  definition(Plain-language 1-2 line description)                                       :text
#  name                                                                                  :string           not null
#  pokedex_color_key(Design token name (e.g. 'pokedex-mind', 'pokedex-body'))            :string
#  pokedex_silhouette_key(Asset name in app/assets/images/academy/pokedex/ (svg))        :string
#  position                                                                              :integer          default(0), not null
#  slug                                                                                  :string           not null
#  created_at                                                                            :datetime         not null
#  updated_at                                                                            :datetime         not null
#
# Indexes
#
#  index_academy_concepts_on_category  (category)
#  index_academy_concepts_on_slug      (slug) UNIQUE
#
require "rails_helper"

RSpec.describe Academy::Concept do
  it "requires slug, name, category" do
    expect(described_class.new).not_to be_valid
  end

  it "rejects invalid slugs" do
    record = build(:academy_concept, slug: "Bad Slug")
    expect(record).not_to be_valid
  end

  it "rejects categories outside the catalog" do
    record = build(:academy_concept, category: "nope")
    expect(record).not_to be_valid
  end

  it "is valid with all the right pieces" do
    expect(build(:academy_concept)).to be_valid
  end

  describe "concept brief accessors" do
    it "the_essence_or_definition returns curated essence when present" do
      c = create(:academy_concept, definition: "fallback def", the_essence: "north star")
      expect(c.the_essence_or_definition).to eq("north star")
    end

    it "the_essence_or_definition falls back to definition when essence blank" do
      c = create(:academy_concept, definition: "fallback def", the_essence: nil)
      expect(c.the_essence_or_definition).to eq("fallback def")
    end

    it "common_confusion_or_nil returns the curated string or nil" do
      c1 = create(:academy_concept, common_confusion: "kids confuse X with Y")
      c2 = create(:academy_concept, common_confusion: nil)
      expect(c1.common_confusion_or_nil).to eq("kids confuse X with Y")
      expect(c2.common_confusion_or_nil).to be_nil
    end

    it "forbidden_terms_list is always an array, empty by default" do
      c1 = create(:academy_concept)
      c2 = create(:academy_concept, forbidden_terms: ["a", "b"])
      expect(c1.forbidden_terms_list).to eq([])
      expect(c2.forbidden_terms_list).to eq(%w[a b])
    end
  end
end
