require "rails_helper"

RSpec.describe ReminderSchedulable do
  # Create a test class that includes our concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "tickets"
      include ReminderSchedulable
      
      attr_accessor :id, :due_date, :user

      def schedule_interval_reminders
        return unless user&.send_due_date_reminder
        return if user.due_date_reminder_interval <= 1

        (2..user.due_date_reminder_interval).each do |interval|
          reminder_date = due_date - interval.days
          schedule_job(reminder_date)
        end
      end
    end
  end

  let(:user) do
    double("User",
      id: 1,
      send_due_date_reminder: true,
      due_date_reminder_interval: 3,
      due_date_reminder_offset: 1,
      due_date_reminder_time: Time.parse("09:00"),
      time_zone: "Europe/Vienna"
    )
  end

  let(:ticket) do
    test_class.new(
      id: 1,
      due_date: 3.days.from_now,
      user: user
    )
  end

  describe "callbacks" do
    context "when creating a new ticket" do
      it "schedules reminder after creation" do
        expect(ticket).to receive(:schedule_single_reminder).once
        expect(ticket).to receive(:schedule_interval_reminders).once
        ticket.save!
      end

      it "does not schedule reminder if due_date is nil" do
        expect(ticket).not_to receive(:schedule_single_reminder)
        expect(ticket).not_to receive(:schedule_interval_reminders)

        ticket.due_date = nil
        ticket.save!
      end

      it "does not schedule reminder if user has reminders disabled" do
        expect(ticket).not_to receive(:schedule_single_reminder)
        expect(ticket).not_to receive(:schedule_interval_reminders)
        
        allow(user).to receive(:send_due_date_reminder).and_return(false)
        ticket.save!
      end
    end

    context "when updating a ticket" do
      let(:real_user) { create(:user) }
      let(:real_ticket) { create(:ticket, user: real_user) }

      it "does not schedule reminder on update" do
        expect(real_ticket).not_to receive(:schedule_reminder)
        
        real_ticket.update!(title: "Updated Title")
      end
    end
  end

  describe "#schedule_interval_reminders" do
    it "schedules correct number of reminders" do
      expect(ticket).to receive(:schedule_job).exactly(2).times
      ticket.send(:schedule_interval_reminders)
    end

    context "when interval is 1" do
      let(:user) do
        double("User",
          id: 1,
          send_due_date_reminder: true,
          due_date_reminder_interval: 1,
          due_date_reminder_offset: 1,
          due_date_reminder_time: Time.parse("09:00"),
          time_zone: "Europe/Vienna"
        )
      end

      it "does not schedule additional reminders" do
        expect(ticket).not_to receive(:schedule_job)
        ticket.send(:schedule_interval_reminders)
      end
    end
  end

  describe "#schedule_job" do
    let(:reminder_datetime) { 1.hour.from_now }

    it "schedules a job with correct parameters" do
      expect(Sidekiq::Client).to receive(:push).with(
        hash_including(
          "class" => DueDateReminderJob,
          "args" => [user.id, ticket.id, "email"]
        )
      )

      ticket.send(:schedule_job, reminder_datetime)
    end

    context "when reminder time has passed" do
      let(:reminder_datetime) { 1.hour.ago }

      it "schedules for next day" do
        expect(Sidekiq::Client).to receive(:push).with(
          hash_including(
            "class" => DueDateReminderJob,
            "args" => [user.id, ticket.id, "email"]
          )
        )

        ticket.send(:schedule_job, reminder_datetime)
      end
    end
  end
end 