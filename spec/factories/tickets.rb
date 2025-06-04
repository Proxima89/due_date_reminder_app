FactoryBot.define do
  factory :ticket do
    association :user
    due_date { 3.days.from_now }
  end
end 