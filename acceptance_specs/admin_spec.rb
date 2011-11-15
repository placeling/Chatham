require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require "rspec"

describe "Admin", :type => :request do

  before(:all) do

    ACCEPTANCE_CONFIG = YAML.load_file("#{::Rails.root.to_s}/acceptance_specs/harness.yml")[::Rails.env]
    @key = ACCEPTANCE_CONFIG['consumer_key']
    @secret = ACCEPTANCE_CONFIG['consumer_secret']
    @username = ACCEPTANCE_CONFIG['username']
    @password = ACCEPTANCE_CONFIG['password']
    @site = ACCEPTANCE_CONFIG['host']
  end

  it "should display status page" do

      res = Net::HTTP.get_response URI.parse(@site + "/admin/status")
      res.code.should be(200)

      res.body.should include("E8455D251B002C7A0E0ADE385C8940E29CE7C139233B31A9889009B37814CA49")
  end
end