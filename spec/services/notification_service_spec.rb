require "rails_helper"

RSpec.describe NotificationService do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user) }
  let(:mailer_double) { double("mailer", deliver_now: true) }

  describe ".notify" do
    it "sends email notification" do
      expect(TicketMailer).to receive(:due_date_reminder)
        .with(user, ticket)
        .and_return(mailer_double)

      described_class.notify(user, ticket, method: :email)
    end

    it "returns nil for unsupported methods" do
      expect(TicketMailer).not_to receive(:due_date_reminder)

      result = described_class.notify(user, ticket, method: :unsupported)
      expect(result).to be_nil
    end
  end
end 
