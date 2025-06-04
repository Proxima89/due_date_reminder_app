require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(
      email: 'test@example.com',
      password: 'password123'
    )
  end

  test "has default reminder settings" do
    assert @user.send_due_date_reminder
    assert_equal 1, @user.due_date_reminder_offset
    assert_equal Time.parse('09:00'), @user.due_date_reminder_time
    assert_equal 0, @user.due_date_reminder_interval
    assert_equal 'Europe/Vienna', @user.time_zone
  end

  test "validates time zone format" do
    @user.time_zone = 'Invalid/Zone'
    assert_not @user.valid?
    assert_includes @user.errors[:time_zone], 'is not a valid time zone'

    @user.time_zone = 'Europe/Vienna'
    assert @user.valid?
  end

  test "validates reminder time format" do
    @user.due_date_reminder_time = 'invalid'
    assert_not @user.valid?
    assert_includes @user.errors[:due_date_reminder_time], 'must be a valid time'

    @user.due_date_reminder_time = Time.parse('09:00')
    assert @user.valid?
  end

  test "validates reminder offset" do
    @user.due_date_reminder_offset = -1
    assert_not @user.valid?
    assert_includes @user.errors[:due_date_reminder_offset], 'must be greater than or equal to 0'

    @user.due_date_reminder_offset = 0
    assert @user.valid?
  end

  test "validates reminder interval" do
    @user.due_date_reminder_interval = -1
    assert_not @user.valid?
    assert_includes @user.errors[:due_date_reminder_interval], 'must be greater than or equal to 0'

    @user.due_date_reminder_interval = 0
    assert @user.valid?
  end

  test "can update reminder settings" do
    @user.update!(
      send_due_date_reminder: false,
      due_date_reminder_offset: 2,
      due_date_reminder_time: Time.parse('10:00'),
      due_date_reminder_interval: 4,
      time_zone: 'America/New_York'
    )

    assert_not @user.send_due_date_reminder
    assert_equal 2, @user.due_date_reminder_offset
    assert_equal Time.parse('10:00'), @user.due_date_reminder_time
    assert_equal 4, @user.due_date_reminder_interval
    assert_equal 'America/New_York', @user.time_zone
  end

  # test "the truth" do
  #   assert true
  # end
end
