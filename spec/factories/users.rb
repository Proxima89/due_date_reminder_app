FactoryBot.define do
  factory :user do
    sequence(:mail) { |n| "user#{n}@example.com" }
    send_due_date_reminder { true }
    due_date_reminder_interval { 3 }
    due_date_reminder_offset { 1 }
    due_date_reminder_time { Time.parse("09:00") }
    time_zone { "Europe/Vienna" }
  end
end 