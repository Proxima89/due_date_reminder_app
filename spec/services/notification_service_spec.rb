require "rails_helper"

RSpec.describe NotificationService do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user) }
  let(:mailer_double) { double("mailer", deliver_now: true) }

  before do
    # Disable callbacks for all tests in this file
    Ticket.skip_callback(:commit, :after, :schedule_reminder)
  end

  after do
    # Re-enable callbacks after tests
    Ticket.set_callback(:commit, :after, :schedule_reminder)
  end

  describe ".notify" do
    context "when method is email" do
      it "sends an email notification" do
        expect(TicketMailer).to receive(:due_date_reminder)
          .with(user, ticket)
          .and_return(mailer_double)

        described_class.notify(user, ticket, method: :email)
      end
    end

    context "when method is not supported" do
      it "does not send any notification" do
        expect(TicketMailer).not_to receive(:due_date_reminder)
        
        result = described_class.notify(user, ticket, method: :unsupported)
        expect(result).to be_nil
      end
    end
  end
end 