class Ticket < ApplicationRecord
  include ReminderSchedulable
  
  belongs_to :user, class_name: 'User', foreign_key: :assigned_user_id
end
