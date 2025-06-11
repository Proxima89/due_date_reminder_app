require "rails_helper"
require "sidekiq/testing"

RSpec.describe ReminderSchedulable do
  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  let(:user) { create(:user, due_date_reminder_interval: 5) }
  let(:ticket) { build(:ticket, user: user, due_date: 7.days.from_now) }

  describe "scheduling reminders" do
    it "creates an initial reminder for the due date" do
      expect {
        ticket.save!
      }.to change(DueDateReminderJob.jobs, :size)

      # Verify initial reminder is scheduled
      jobs = DueDateReminderJob.jobs
      expect(jobs).not_to be_empty
    end

    it "creates interval reminders (1 to 5 days before due date)" do
      expect {
        ticket.save!
      }.to change(DueDateReminderJob.jobs, :size).by(6) # 1 initial + 5 interval reminders

      # Verify correct number of jobs scheduled
      jobs = DueDateReminderJob.jobs
      expect(jobs.size).to eq(6)
      expect(jobs.all? { |job| job["args"] == [user.id, ticket.id] }).to be true
    end
  end
end 
