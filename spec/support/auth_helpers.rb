module AuthHelpers
  # Request-spec helper: authenticate the family (sets signed cookie) then
  # select a profile via PIN. Uses the new Family/Profile session controllers.
  #
  # Note: relies on Rails' integration test cookie jar which automatically
  # persists Set-Cookie headers across requests, so the family_id cookie set
  # by FamilySessionsController#create is reused by ProfileSessionsController#create.
  def sign_in_as(profile, pin: "1234")
    post family_session_path, params: { email: profile.family.email, password: "supersecret1234" }
    post profile_session_path, params: { profile_id: profile.id, pin: pin }
  end
end
