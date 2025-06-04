require "rails_helper"
require "sidekiq/testing"

RSpec.describe ScheduledDueDateReminderJob do
  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Testing.inline!
  end

  describe "#perform" do
    it "calls DueDateReminder::Service.send_due_reminders" do
      expect(DueDateReminder::Service).to receive(:send_due_reminders)
      described_class.new.perform
    end
  end
end 