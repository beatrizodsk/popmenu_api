FactoryBot.define do
  factory :menu_item do
    sequence(:name) { |n| "Menu Item #{n}" }
    price { 9.99 }
    association :menu

    trait :without_menu do
      menu { nil }
    end

    trait :invalid do
      name { '' }
      price { -1 }
    end
  end
end
