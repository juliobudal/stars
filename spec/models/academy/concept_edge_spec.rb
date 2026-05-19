# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_concept_edges
#
#  id                                                   :bigint           not null, primary key
#  edge_type(v4 typed edge — see migration header)     :string           default("relates_to"), not null
#  kind(0=echoes (symmetric), 1=depends_on, 2=leads_to) :integer          default("echoes"), not null
#  created_at                                           :datetime         not null
#  updated_at                                           :datetime         not null
#  from_concept_id                                      :bigint           not null
#  to_concept_id                                        :bigint           not null
#
# Indexes
#
#  idx_academy_concept_edges_edge_type             (edge_type)
#  idx_academy_concept_edges_unique                (from_concept_id,to_concept_id,kind) UNIQUE
#  index_academy_concept_edges_on_from_concept_id  (from_concept_id)
#  index_academy_concept_edges_on_to_concept_id    (to_concept_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_concept_id => academy_concepts.id)
#  fk_rails_...  (to_concept_id => academy_concepts.id)
#
require "rails_helper"

RSpec.describe Academy::ConceptEdge do
  let(:a) { create(:academy_concept, slug: "a") }
  let(:b) { create(:academy_concept, slug: "b") }

  it "rejects self-referential edges" do
    edge = described_class.new(from_concept: a, to_concept: a, kind: :echoes)
    expect(edge).not_to be_valid
    expect(edge.errors[:to_concept_id]).to be_present
  end

  it "enforces uniqueness on (from, to, kind)" do
    described_class.create!(from_concept: a, to_concept: b, kind: :echoes)
    dup = described_class.new(from_concept: a, to_concept: b, kind: :echoes)
    expect(dup).not_to be_valid
  end

  it "allows different kinds between the same pair" do
    described_class.create!(from_concept: a, to_concept: b, kind: :echoes)
    other = described_class.new(from_concept: a, to_concept: b, kind: :depends_on)
    expect(other).to be_valid
  end
end
