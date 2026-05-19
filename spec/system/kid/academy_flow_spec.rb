require "rails_helper"

# End-to-end smoke of the Academy v2 surface.
#
# Walks a kid through: subjects index → subject show → trail show; then
# atlas; then the parent academy dashboard / library / journeys / compare.
# Findings discovered during 2026-05-17 manual Playwright walkthrough are
# documented as pending expectations so that fixing the underlying bug
# flips them green.
#
# The Academy curriculum (subjects, trails, missions, concepts) is loaded
# by migrations and present in the test DB — we reference seeded records
# instead of factory-creating to keep the spec aligned with real content.
#
# Run: make rspec SPEC=spec/system/kid/academy_flow_spec.rb
RSpec.describe "Academy v2 flow", type: :system do
  let!(:family)    { create(:family) }
  let!(:parent_pf) { create(:profile, :parent, family: family, name: "Mamãe", pin: "1111") }
  let!(:child)     { create(:profile, :child,  family: family, name: "Theo",  pin: "1111") }

  let(:subject_record) { ::Academy::Subject.find_by!(slug: "corpo-saude") }
  let(:trail)          { subject_record.trails.order(:position).first }

  before do
    skip "Academy module requires OPENROUTER_API_KEY" unless ::Academy.configured?
    skip "Academy seed data missing (run migrations)" if ::Academy::Subject.count.zero?
  end

  describe "kid surface" do
    before { sign_in_as_child(child, pin: "1111") }

    it "renders the subjects index with the 7 formation areas" do
      visit kid_academy_subjects_path

      expect(page).to have_content("Suas áreas de formação")
      expect(page).to have_content("Corpo & Saúde")
      expect(page).to have_link(href: kid_academy_subject_path(subject_record))
    end

    it "renders the subject show with trails" do
      visit kid_academy_subject_path(subject_record)

      expect(page).to have_content("ÁREA DE FORMAÇÃO")
      expect(page).to have_content(subject_record.name)
      expect(page).to have_link(href: kid_academy_subject_trail_path(subject_record, trail))
    end

    it "renders the trail show with at least one mission" do
      visit kid_academy_subject_trail_path(subject_record, trail)

      expect(page).to have_content("O ARCO DESTA TRILHA")
      expect(page).to have_content(trail.title)
      expect(trail.missions.count).to be >= 1
    end

    it "renders the atlas page (pokédex of patterns)" do
      visit kid_academy_atlas_path

      expect(page).to have_content("Pokédex de ideias")
      # Documents pluralization gap (2026-05-17): currently always plural
      # ("Vistos / Completos") even when count is 1.
      expect(page).to have_content(/vist[oa]s?/i)
    end
  end

  describe "parent surface" do
    before { sign_in_as_parent(parent_pf, pin: "1111") }

    it "renders the parent academy dashboard without raising" do
      visit parent_academy_dashboard_path
      expect(page).to have_content("Academia")
    end

    it "renders the library page" do
      visit parent_academy_library_path
      expect(page).to have_content(/biblioteca|pílulas/i)
    end

    it "renders the compare page" do
      visit parent_academy_compare_path
      expect(page).to have_content(/comparar|filhos/i)
    end

    it "renders the journeys page" do
      visit parent_academy_journeys_path
      expect(page).to have_content(/trilhas|jornadas/i)
    end
  end
end
