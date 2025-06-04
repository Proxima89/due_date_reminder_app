module DueDateReminder
  class Service
    def self.send_due_reminders
      User.where(send_due_date_reminder: true).find_each do |user|
        process_user_reminders(user)
      end
    end

    def self.process_user_reminders(user)
      tz = ActiveSupport::TimeZone[user.time_zone]
      now = Time.current.in_time_zone(tz)
      reminder_time = user.due_date_reminder_time

      # Only process if current time matches the user's reminder time
      return unless now.strftime("%H:%M") == reminder_time.strftime("%H:%M")

      user.tickets.find_each do |ticket|
        next unless should_send_reminder?(user, ticket, now, tz)
        Sidekiq::Client.push(
          "class" => DueDateReminderJob,
          "args" => [user.id, ticket.id]
        )
      end
    end

    def self.should_send_reminder?(user, ticket, now, tz)
      return false if ticket.due_date.nil?

      due_date = ticket.due_date.in_time_zone(tz)
      reminder_date = due_date - user.due_date_reminder_offset.days

      # Check if today is the reminder date
      now.to_date == reminder_date.to_date
    end
  end
end
