require "rails_helper"

RSpec.describe Tasks::CreateCustomService do
  let(:family) { create(:family) }
  let(:profile) { create(:profile, family: family, role: :child) }
  let(:category) { create(:category, family: family) }

  let(:valid_params) do
    {
      custom_title: "Arrumei a estante",
      custom_description: "Tirei o pó",
      custom_points: 25,
      custom_category_id: category.id,
      submission_comment: "Foi rapidinho"
    }
  end

  it "creates an awaiting_approval custom ProfileTask" do
    result = described_class.call(profile: profile, params: valid_params)

    expect(result).to be_success
    pt = result.data
    expect(pt).to be_persisted
    expect(pt.source).to eq("custom")
    expect(pt.status).to eq("awaiting_approval")
    expect(pt.profile).to eq(profile)
    expect(pt.custom_title).to eq("Arrumei a estante")
    expect(pt.custom_points).to eq(25)
    expect(pt.custom_category).to eq(category)
    expect(pt.submission_comment).to eq("Foi rapidinho")
    expect(pt.assigned_date).to eq(Date.current)
    expect(pt.completed_at).to be_within(2.seconds).of(Time.current)
  end

  it "returns failure when title missing" do
    result = described_class.call(profile: profile, params: valid_params.merge(custom_title: nil))
    expect(result).not_to be_success
    expect(result.error).to be_present
  end

  it "returns failure when points out of range" do
    result = described_class.call(profile: profile, params: valid_params.merge(custom_points: 0))
    expect(result).not_to be_success
  end
end
