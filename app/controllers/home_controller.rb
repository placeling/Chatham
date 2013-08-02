class HomeController < ApplicationController
  before_filter :login_required, :only => [:escape_pod]

  def index
    respond_to do |format|
      format.html
    end
  end


  def escape_pod


  end

  def error503

    render file: "#{Rails.root}/public/503.html", status: 503, :format => :html

  end


end
