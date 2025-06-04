class NotificationService
    def self.notify(user, ticket, method: :email)
      case method.to_sym
      when :email
        TicketMailer.due_date_reminder(user, ticket).deliver_now
      when :sms
        # Future SMS logic
        nil
      when :push
        # Future push logic
        nil
      else
        # Unsupported method - return nil without sending any notification
        nil
      end
    end
  end