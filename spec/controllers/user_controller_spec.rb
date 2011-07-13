require 'spec_helper'

describe UserController do

  describe "GET 'profile'" do
    it "should be successful" do
      get 'profile'
      response.should be_success
    end
  end

end
