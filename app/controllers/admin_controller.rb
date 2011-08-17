class AdminController < ApplicationController
  def terms_of_service
    @terms = t("tos")
    respond_to do |format|
      format.json { render :json => {:terms => @terms} }
      format.html
    end
  end

  def privacy_policy
    @privacy = t("privacy")
    respond_to do |format|
      format.json { render :json => {:privacy => @privacy} }
      format.html
    end
  end

  def about_us
  end

  def contact_us
  end

end
