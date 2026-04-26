FactoryBot.define do
  factory :category do
    family
    sequence(:name) { |n| "Categoria #{n}" }
    icon { "bookmark-01" }
    color { "lilac" }
    position { 0 }
  end
end
