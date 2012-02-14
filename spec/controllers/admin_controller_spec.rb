require 'spec_helper'

describe AdminController do

  describe "GET 'terms_of_service'" do
    it "should be successful" do
      get 'terms_of_service'
      response.should be_success
    end

    it "should be return json if requested" do
      get 'terms_of_service', :format =>:json
      response.should be_success
      tos =  Hashie::Mash.new( JSON.parse( response.body ) )
      tos.terms.should_not be(nil)
      tos.terms.should_not be("")

    end
  end

  describe "GET 'privacy_policy'" do
    it "should be successful" do
      get 'privacy_policy'
      response.should be_success
    end

    it "should be return json if requested" do
      get 'privacy_policy', :format =>:json
      response.should be_success

      response.should be_success
      privacy_policy =  Hashie::Mash.new( JSON.parse( response.body ) )
      privacy_policy.privacy.should_not be(nil)
      privacy_policy.privacy.should_not be("")
    end
  end

  describe "GET 'about_us'" do
    it "should be successful" do
      get 'about_us'
      response.should be_success
    end
  end

  describe "GET 'investors'" do
    it "should be successful" do
      get 'investors'
      response.should be_success
    end
  end

end
