require "rails_helper"
require "sidekiq/testing"

RSpec.describe DueDateReminderJob do
  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket, user: user) }

    it "calls NotificationService with correct arguments" do
      expect(NotificationService).to receive(:notify)
        .with(user, ticket, method: :email)

      described_class.new.perform(user.id, ticket.id, "email")
    end

    it "uses email as default method" do
      expect(NotificationService).to receive(:notify)
        .with(user, ticket, method: :email)

      described_class.new.perform(user.id, ticket.id)
    end
  end
end 
