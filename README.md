# Due Date Reminder App

A Rails application that helps users manage and receive reminders for ticket due dates. The application allows users to configure their reminder preferences and automatically sends notifications when tickets are approaching their due dates.

## Features

- User-specific reminder settings
  - Enable/disable reminders
  - Configure reminder intervals
  - Set reminder time and timezone
  - Customize reminder offset (days before due date)
- Multiple notification methods (currently email, with SMS and push notifications planned)
- Background job processing with Sidekiq
- Timezone-aware scheduling
- Configurable reminder intervals

## Prerequisites

- Ruby 3.2.0 or higher
- Rails 8.0.0 or higher
- PostgreSQL
- Redis (for Sidekiq)
- SMTP server for email notifications

## Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:Proxima89/due_date_reminder_app.git
   cd due_date_reminder_app
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. Start Redis (required for Sidekiq):
   ```bash
   redis-server
   ```

6. Start Sidekiq:
   ```bash
   bundle exec sidekiq
   ```

7. Start the Rails server:
   ```bash
   rails server
   ```

## Configuration

### User Settings

Users can configure their reminder preferences:
- `send_due_date_reminder`: Enable/disable reminders (default: true)
- `due_date_reminder_interval`: Number of reminders to send (default: 0)
- `due_date_reminder_offset`: Days before due date to send first reminder (default: 0)
- `due_date_reminder_time`: Time of day to send reminders (default: 09:00)
- `time_zone`: User's timezone (default: Europe/Vienna)

### Email Configuration

Configure your SMTP settings in `config/environments/`:
```ruby
config.action_mailer.smtp_settings = {
  address: "smtp.example.com",
  port: 587,
  authentication: :plain,
  user_name: ENV["SMTP_USERNAME"],
  password: ENV["SMTP_PASSWORD"]
}
```

## Usage

### Creating Tickets

Tickets can be created with a due date:
```ruby
ticket = Ticket.create!(
  title: "Important Task",
  description: "Complete this task",
  due_date: 1.week.from_now,
  assigned_user_id: user.id
)
```

### Managing Reminders

Reminders are automatically scheduled when:
- A new ticket is created
- A ticket's due date is updated
- A user's reminder settings are changed

### Viewing Scheduled Jobs

Access the Sidekiq web interface at `/sidekiq` to monitor scheduled jobs.

## Testing

Run the test suite:
```bash
bundle exec rspec
```

The application uses:
- RSpec for testing
- FactoryBot for test data
- Shoulda Matchers for model testing
- Sidekiq testing helpers

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
