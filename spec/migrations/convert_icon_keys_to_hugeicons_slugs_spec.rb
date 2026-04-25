require "rails_helper"

migration_dir = Rails.root.join("db/migrate")
migration_path = Dir.glob(migration_dir.join("*_convert_icon_keys_to_hugeicons_slugs.rb")).first
require migration_path

RSpec.describe ConvertIconKeysToHugeiconsSlugs do
  let(:family) { create(:family) }

  it "rewrites curated keys to raw slugs on global_tasks" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "rewrites curated keys to raw slugs on rewards" do
    reward = Reward.create!(family: family, title: "R", icon: "iceCream", cost: 5)
    described_class.new.up
    expect(reward.reload.icon).to eq("ice-cream-01")
  end

  it "leaves raw slugs untouched" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed-single-01", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "is idempotent on re-run" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed", points: 1, frequency: "daily")
    described_class.new.up
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "leaves unknown keys untouched" do
    task = GlobalTask.create!(family: family, title: "T", icon: "wat", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("wat")
  end
end
