class TicketMailer < ApplicationMailer
  def due_date_reminder(user, ticket)
    @user = user
    @ticket = ticket
    mail(to: @user.mail, subject: "Ticket Due Date Reminder")
  end
end
