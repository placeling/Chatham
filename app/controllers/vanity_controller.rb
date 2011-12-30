class VanityController < ApplicationController
  before_filter :admin_required

  #include Vanity::Rails::Dashboard
end