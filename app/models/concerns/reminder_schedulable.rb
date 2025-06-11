module ReminderSchedulable
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_reminders, on: :create
  end

  private

  def schedule_reminders
    schedule_initial_reminder
    schedule_interval_reminders
  end

  def schedule_initial_reminder
    schedule_reminder_for_date(due_date)
  end

  def schedule_interval_reminders
    return unless user&.due_date_reminder_interval > 0

    # Schedule reminders based on interval
    (1..user.due_date_reminder_interval).each do |interval|
      reminder_date = due_date - interval.days
      # Only schedule if the reminder date is in the future
      schedule_reminder_for_date(reminder_date) if reminder_date > Date.current
    end
  end

  def schedule_reminder_for_date(date)
    return unless user&.send_due_date_reminder?

    reminder_time = user.due_date_reminder_time
    offset_day = user.due_date_reminder_offset
    reminder_date = date - offset_day.day

    scheduled_time = reminder_date.in_time_zone(user.time_zone).change(
      hour: reminder_time.hour,
      min: reminder_time.min
    ) # .in_time_zone converts a Date to a Time object in the specified timezone, takes the date and sets it to midnight (00:00:00) in that timezone.

    Sidekiq::Client.push(
      "class" => DueDateReminderJob,
      "args" => [user.id, id],
      "at" => scheduled_time.to_i
    )
  end
end
