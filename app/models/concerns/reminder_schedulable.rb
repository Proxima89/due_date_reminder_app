module ReminderSchedulable
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_reminder, on: :create
  end

  private

  def schedule_reminder
    return unless due_date && user&.send_due_date_reminder

    # Schedule initial reminder
    schedule_single_reminder(initial_reminder_datetime)
    
    # Schedule additional reminders based on interval
    if user.due_date_reminder_interval > 1
      schedule_interval_reminders
    end
  end

  def schedule_single_reminder(datetime)
    schedule_job(datetime)
  end

  def schedule_interval_reminders
    total_reminders = user.due_date_reminder_interval
    initial_time = initial_reminder_datetime
    due_date_time = due_date.in_time_zone(user.time_zone)
    
    hours_between_reminders = calculate_hours_between_reminders(initial_time, due_date_time, total_reminders)
    schedule_additional_reminders(initial_time, hours_between_reminders, total_reminders, due_date_time)
  end

  def calculate_hours_between_reminders(initial_time, due_date_time, total_reminders)
    total_hours = ((due_date_time - initial_time) / 3600).round
    total_hours / (total_reminders - 1)
  end

  def schedule_additional_reminders(initial_time, hours_between_reminders, total_reminders, due_date_time)
    (total_reminders - 1).times do |i|
      reminder_time = initial_time + (hours_between_reminders * (i + 1)).hours
      break if reminder_time >= due_date_time
      schedule_job(reminder_time)
    end
  end

  def initial_reminder_datetime
    tz = ActiveSupport::TimeZone[user.time_zone]
    reminder_date = due_date.in_time_zone(tz) - user.due_date_reminder_offset.days
    reminder_date.to_time.change(
      hour: user.due_date_reminder_time.hour,
      min: user.due_date_reminder_time.min,
      sec: 0
    )
  end

  def schedule_job(reminder_datetime)
    # If the reminder time has passed, schedule for next day
    if reminder_datetime <= Time.current
      reminder_datetime = reminder_datetime + 1.day
    end

    # Calculate minutes until the reminder should be sent
    minutes_until_reminder = ((reminder_datetime - Time.current) / 60).round

    # Only schedule if the reminder is in the future
    return if minutes_until_reminder <= 0

    # Schedule the job
    Sidekiq::Client.push(
      "class" => DueDateReminderJob,
      "args" => [user.id, id, "email"], # Use string instead of symbol
      "at" => Time.current.to_f + (minutes_until_reminder * 60)
    )
  end
end 