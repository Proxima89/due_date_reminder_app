require "rails_helper"
require "sidekiq/testing"

RSpec.describe Ticket, type: :model do
  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Testing.inline!
  end

  describe "associations" do
    it { should belong_to(:user).class_name("User").with_foreign_key("assigned_user_id") }
  end

  describe "callbacks" do
    let(:user) { create(:user) }
    let(:ticket) { build(:ticket, user: user) }

    it "schedules initial and interval reminders after creation" do
      expect {
        ticket.save!
      }.to change(DueDateReminderJob.jobs, :size).by(2) # One for initial, one for interval

      # Verify the jobs are scheduled with correct arguments
      expect(DueDateReminderJob.jobs.last(2).map { |job| job["args"] })
        .to contain_exactly([user.id, ticket.id, "email"], [user.id, ticket.id, "email"])
    end

    context "when user has interval set to 1" do
      before do
        user.update!(due_date_reminder_interval: 1)
      end

      it "schedules only initial reminder" do
        expect {
          ticket.save!
        }.to change(DueDateReminderJob.jobs, :size).by(1)

        expect(DueDateReminderJob.jobs.last["args"]).to eq([user.id, ticket.id, "email"])
      end
    end
  end
end 