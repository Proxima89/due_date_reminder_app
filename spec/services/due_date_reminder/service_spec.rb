require "rails_helper"
require "sidekiq/testing"

RSpec.describe DueDateReminder::Service do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user, due_date: 1.day.from_now) }
  let(:tz) { ActiveSupport::TimeZone[user.time_zone] }
  let(:now) { Time.current.in_time_zone(tz) }

  before do
    allow(Time).to receive(:current).and_return(now)
    Sidekiq::Testing.fake! # Enable fake mode for all tests
  end

  after do
    Sidekiq::Testing.inline! # Reset to inline mode after tests
  end

  describe ".send_due_reminders" do
    context "with enabled reminders" do
      it "processes reminders for the user" do
        expect(described_class).to receive(:process_user_reminders).with(user)
        described_class.send_due_reminders
      end
    end

    context "with disabled reminders" do
      before { user.update!(send_due_date_reminder: false) }

      it "skips the user" do
        expect(described_class).not_to receive(:process_user_reminders).with(user)
        described_class.send_due_reminders
      end
    end
  end

  describe ".process_user_reminders" do
    context "when reminder time matches" do
      before do
        allow(now).to receive(:strftime).with("%H:%M")
          .and_return(user.due_date_reminder_time.strftime("%H:%M"))
      end

      context "with valid ticket" do
        it "schedules a reminder job" do
          # Debug output
          puts "\nDebug info:"
          puts "User reminder time: #{user.due_date_reminder_time.strftime('%H:%M')}"
          puts "Current time: #{now.strftime('%H:%M')}"
          puts "Ticket due date: #{ticket.due_date}"
          puts "User reminder offset: #{user.due_date_reminder_offset}"
          puts "Should send reminder?: #{described_class.should_send_reminder?(user, ticket, now, tz)}"

          expect {
            described_class.process_user_reminders(user)
          }.to change(DueDateReminderJob.jobs, :size).by(1)
          
          expect(DueDateReminderJob.jobs.last["args"]).to eq([user.id, ticket.id])
        end
      end

      context "with invalid ticket" do
        before { ticket.update!(due_date: nil) }

        it "skips scheduling" do
          expect {
            described_class.process_user_reminders(user)
          }.not_to change(DueDateReminderJob.jobs, :size)
        end
      end
    end

    context "when reminder time doesn't match" do
      before do
        allow(now).to receive(:strftime).with("%H:%M").and_return("10:00")
      end

      it "skips scheduling" do
        expect {
          described_class.process_user_reminders(user)
        }.not_to change(DueDateReminderJob.jobs, :size)
      end
    end
  end

  describe ".should_send_reminder?" do
    context "with invalid ticket" do
      before { ticket.update!(due_date: nil) }

      it "returns false" do
        expect(described_class.should_send_reminder?(user, ticket, now, tz))
          .to be false
      end
    end

    context "with valid ticket" do
      context "when not on reminder date" do
        before do
          allow(now).to receive(:to_date)
            .and_return((ticket.due_date - 2.days).to_date)
        end

        it "returns false" do
          expect(described_class.should_send_reminder?(user, ticket, now, tz))
            .to be false
        end
      end

      context "when on reminder date" do
        before do
          allow(now).to receive(:to_date)
            .and_return((ticket.due_date - user.due_date_reminder_offset.days).to_date)
        end

        it "returns true" do
          expect(described_class.should_send_reminder?(user, ticket, now, tz))
            .to be true
        end
      end
    end
  end
end 