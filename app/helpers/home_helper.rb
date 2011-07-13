module HomeHelper
  def admin_user?
    if current_user
      return current_user.is_admin?
    else
      return false
    end
  end
end
