require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      send_due_date_reminder: true,
      due_date_reminder_offset: 1,
      due_date_reminder_time: Time.parse('09:00'),
      due_date_reminder_interval: 4,
      time_zone: 'Europe/Vienna'
    )
  end

  test "schedules reminder when ticket is created" do
    ticket = Ticket.create!(
      title: 'Test Ticket',
      due_date: 2.days.from_now,
      assigned_user_id: @user.id
    )

    # Verify that a job was scheduled
    assert_job_scheduled(ticket)
  end

  test "schedules multiple reminders based on interval" do
    ticket = Ticket.create!(
      title: 'Test Ticket',
      due_date: 2.days.from_now,
      assigned_user_id: @user.id
    )

    # Verify that multiple jobs were scheduled
    scheduled_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'DueDateReminderJob' && job.args == [@user.id, ticket.id]
    end

    # Should have at least 2 jobs: initial reminder and one interval reminder
    assert scheduled_jobs.size >= 2, "Expected at least 2 scheduled jobs, got #{scheduled_jobs.size}"
  end

  test "reschedules reminder when due date changes" do
    ticket = Ticket.create!(
      title: 'Test Ticket',
      due_date: 2.days.from_now,
      assigned_user_id: @user.id
    )

    # Get initial scheduled jobs
    initial_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'DueDateReminderJob' && job.args == [@user.id, ticket.id]
    end

    # Update due date
    ticket.update!(due_date: 3.days.from_now)

    # Get new scheduled jobs
    new_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'DueDateReminderJob' && job.args == [@user.id, ticket.id]
    end

    # Verify that old jobs were cancelled and new ones were scheduled
    assert_not_equal initial_jobs, new_jobs
    assert new_jobs.any?
  end

  test "does not schedule reminder when user has reminders disabled" do
    @user.update!(send_due_date_reminder: false)

    ticket = Ticket.create!(
      title: 'Test Ticket',
      due_date: 2.days.from_now,
      assigned_user_id: @user.id
    )

    # Verify that no jobs were scheduled
    scheduled_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'DueDateReminderJob' && job.args == [@user.id, ticket.id]
    end

    assert_empty scheduled_jobs
  end

  private

  def assert_job_scheduled(ticket)
    scheduled_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'DueDateReminderJob' && job.args == [@user.id, ticket.id]
    end

    assert scheduled_jobs.any?, "Expected at least one scheduled job"
  end
end
