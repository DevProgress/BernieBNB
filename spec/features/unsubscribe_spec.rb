require 'spec_helper'
require 'rails_helper'
require_relative '../support/feature_test_helper'

RSpec.describe "User unsubscribes", type: :feature do
  before do
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]

    @user = FactoryGirl.create(:user, email: "jojo@yahoo.com", first_name: "Jojo",
                               phone: "2345678901")
  end

  scenario 'User unsubscribes' do
    visit unsubscribe_user_url(@user.confirm_token)
    click_button("Click here to unsubscribe")

    expect(page).to have_content("OK, your account is deleted.")
  end
end

