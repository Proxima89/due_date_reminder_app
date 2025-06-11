require "rails_helper"
require "sidekiq/testing"

RSpec.describe Ticket, type: :model do
  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  describe "associations" do
    it { should belong_to(:user).class_name("User").with_foreign_key("assigned_user_id") }
  end

  describe "callbacks" do
    let(:user) { create(:user) }
    let(:ticket) { build(:ticket, user: user, due_date: 5.days.from_now) }

    it "schedules initial and interval reminders after creation" do
      expect {
        ticket.save!
      }.to change(DueDateReminderJob.jobs, :size).by(4) # 1 initial + 3 interval reminders

      # Verify the jobs are scheduled with correct arguments
      jobs = DueDateReminderJob.jobs.last(4)
      expect(jobs.all? { |job| job["args"] == [user.id, ticket.id] }).to be true
    end

    context "when user has interval set to 1" do
      before do
        user.update!(due_date_reminder_interval: 1)
      end

      it "schedules initial and one interval reminder" do
        expect {
          ticket.save!
        }.to change(DueDateReminderJob.jobs, :size).by(2) # 1 initial + 1 interval

        jobs = DueDateReminderJob.jobs.last(2)
        expect(jobs.all? { |job| job["args"] == [user.id, ticket.id] }).to be true
      end
    end
  end
end 
