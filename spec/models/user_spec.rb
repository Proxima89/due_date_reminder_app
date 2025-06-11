require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:tickets).with_foreign_key("assigned_user_id") }
  end

  describe "validations" do
    it { should validate_presence_of(:mail) }
    it { should validate_uniqueness_of(:mail).case_insensitive }
  end

  describe "reminder settings" do
    let(:user) { build(:user) }

    it "validates reminder interval range" do
      user.due_date_reminder_interval = 31
      expect(user).not_to be_valid
    end

    it "accepts valid timezone" do
      user.time_zone = "Europe/Vienna"
      expect(user).to be_valid
    end
  end
end 
