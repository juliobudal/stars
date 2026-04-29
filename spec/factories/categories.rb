# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  color      :string           not null
#  icon       :string           not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_categories_on_family_id               (family_id)
#  index_categories_on_family_id_and_name      (family_id,name) UNIQUE
#  index_categories_on_family_id_and_position  (family_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
FactoryBot.define do
  factory :category do
    family
    sequence(:name) { |n| "Categoria #{n}" }
    icon { "bookmark-01" }
    color { "lilac" }
    position { 0 }
  end
end
