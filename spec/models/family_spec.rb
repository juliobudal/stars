# == Schema Information
#
# Table name: families
#
#  id                     :bigint           not null, primary key
#  allow_negative         :boolean          default(FALSE)
#  auto_approve_threshold :integer
#  decay_enabled          :boolean          default(FALSE)
#  locale                 :string           default("pt-BR")
#  max_debt               :integer          default(100), not null
#  name                   :string
#  require_photo          :boolean          default(FALSE)
#  timezone               :string           default("America/Sao_Paulo")
#  week_start             :integer          default(1)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require "rails_helper"

RSpec.describe Family, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:profiles).dependent(:destroy) }
    it { is_expected.to have_many(:global_tasks).dependent(:destroy) }
    it { is_expected.to have_many(:rewards).dependent(:destroy) }
  end
end
