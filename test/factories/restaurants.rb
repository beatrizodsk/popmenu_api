FactoryBot.define do
  factory :restaurant do
    sequence(:name) { |n| "Restaurant #{n}" }

    trait :with_menus do
      transient do
        menus_count { 2 }
      end

      after(:create) do |restaurant, evaluator|
        create_list(:menu, evaluator.menus_count, restaurant: restaurant)
      end
    end

    trait :empty do
      after(:create) do |restaurant|
        restaurant.menus.destroy_all
      end
    end
  end
end
