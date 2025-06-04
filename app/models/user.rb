class User < ApplicationRecord
  has_many :tickets, foreign_key: :assigned_user_id

  validates :mail, presence: true, uniqueness: { case_sensitive: false }
  validates :time_zone, presence: true
  validates :due_date_reminder_interval, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 30 
  }
  validate :time_zone_exists
  validate :valid_reminder_time

  # Ensure timezone exists
  def time_zone_exists
    return if time_zone.blank?
    unless ActiveSupport::TimeZone[time_zone]
      errors.add(:time_zone, "is not a valid timezone")
    end
  end

  # Ensure reminder time is valid
  def valid_reminder_time
    return if due_date_reminder_time.blank?
    unless due_date_reminder_time.is_a?(Time)
      errors.add(:due_date_reminder_time, "must be a valid time")
    end
  end
end
