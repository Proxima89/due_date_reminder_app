class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :mail
      t.boolean :send_due_date_reminder, default: true # Indicates whether the user wants to recieve reminders
      t.integer :due_date_reminder_interval, default: 0 # Indicates for how often to send the reminders
      t.integer :due_date_reminder_offset, default: 0 # How many days, before the due date, the reminder should be sent
      t.time :due_date_reminder_time, default: -> { "'09:00:00'" } # The time of day in user's time zone when the reminder should be sent
      t.string :time_zone, default: "Europe/Vienna"

      t.timestamps
    end
  end
end
