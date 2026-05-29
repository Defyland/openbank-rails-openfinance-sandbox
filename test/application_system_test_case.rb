require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  def sign_in_as_operator
    visit new_session_path
    fill_in "Email", with: users(:operator).email_address
    fill_in "Password", with: "password-12345"
    click_on "Sign in"
  end
end
