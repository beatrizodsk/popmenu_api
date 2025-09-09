FactoryBot.define do
  factory :menu do
    sequence(:name) { |n| "Menu #{n}" }
    association :restaurant

    trait :with_menu_items do
      transient do
        menu_items_count { 3 }
      end

      after(:create) do |menu, evaluator|
        menu_items = create_list(:menu_item, evaluator.menu_items_count)
        menu.menu_items << menu_items
      end
    end

    trait :empty do
      after(:create) do |menu|
        menu.menu_items.destroy_all
      end
    end

    trait :without_restaurant do
      restaurant { nil }
    end
  end
end
