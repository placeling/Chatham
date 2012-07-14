class VanityController < ApplicationController
  include Vanity::Rails::Dashboard
  include Vanity::Rails::TrackingImage

  before_filter :admin_required
end