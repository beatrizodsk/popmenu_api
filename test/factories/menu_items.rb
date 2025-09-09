FactoryBot.define do
  factory :menu_item do
    sequence(:name) { |n| "Menu Item #{n}" }
    price { 9.99 }

    trait :with_menus do
      transient do
        menus_count { 1 }
      end

      after(:create) do |menu_item, evaluator|
        create_list(:menu, evaluator.menus_count, menu_items: [menu_item])
      end
    end

    trait :invalid do
      name { '' }
      price { -1 }
    end
  end
end
