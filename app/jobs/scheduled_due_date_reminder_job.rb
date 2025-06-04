class ScheduledDueDateReminderJob
  include Sidekiq::Job

  def perform
    DueDateReminder::Service.send_due_reminders
  end
end 