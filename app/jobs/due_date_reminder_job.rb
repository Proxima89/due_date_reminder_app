require "sidekiq"

class DueDateReminderJob
  include Sidekiq::Job

  def perform(user_id, ticket_id, method = "email")
    user = User.find(user_id)
    ticket = Ticket.find(ticket_id)
    NotificationService.notify(user, ticket, method: method.to_sym)
  end
end
