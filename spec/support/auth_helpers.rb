module AuthHelpers
  def sign_in_as(profile)
    if profile.parent?
      post sessions_path, params: { email: profile.email, password: "supersecret1234" }
    else
      post sessions_path, params: { profile_id: profile.id }
    end
  end
end
