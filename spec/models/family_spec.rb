require "rails_helper"

RSpec.describe Family, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:profiles).dependent(:destroy) }
    it { is_expected.to have_many(:global_tasks).dependent(:destroy) }
    it { is_expected.to have_many(:rewards).dependent(:destroy) }
  end
end
