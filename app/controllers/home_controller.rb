class HomeController < ApplicationController
  def index
    family = Family.find_by(id: cookies.signed[:family_id])
    return redirect_to new_family_session_path unless family

    profile = session[:profile_id] && family.profiles.find_by(id: session[:profile_id])
    return redirect_to new_profile_session_path unless profile

    redirect_to profile.parent? ? parent_root_path : kid_root_path
  end
end
