require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'oauth'

describe "OAuth Provider" do

  before(:all) do

    ACCEPTANCE_CONFIG = YAML.load_file("#{::Rails.root.to_s}/acceptance_specs/harness.yml")[::Rails.env]
    @key = ACCEPTANCE_CONFIG['consumer_key']
    @secret = ACCEPTANCE_CONFIG['consumer_secret']
    @username = ACCEPTANCE_CONFIG['username']
    @password = ACCEPTANCE_CONFIG['password']
    @site = ACCEPTANCE_CONFIG['host']
  end

  describe "using Xauth" do
    describe "fail on an api request without proper" do
      it "password" do
        consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
        lambda {
          consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => @username, :x_auth_password => "tartus69" })
        }.should raise_error(OAuth::Unauthorized, "401 Unauthorized")
      end

      it "username" do
        consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
        lambda {
          consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => "blah", :x_auth_password => @password })
        }.should raise_error(OAuth::Unauthorized,  "401 Unauthorized")
      end
    end

    it "grant access to the api on a valid request" do

      consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
      access_token = consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => @username, :x_auth_password => @password })

      consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
      access_token = OAuth::AccessToken.new(consumer, access_token.token, access_token.secret)

      response = access_token.get('/v1/users/tyler')
    end

    it "fail on an api request without proper keys" do

      consumer = OAuth::Consumer.new(@key, "blah blah", :site => @site)
      lambda {
        consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => @username, :x_auth_password => @password })
      }.should raise_error(OAuth::Unauthorized, "403 Forbidden")
    end

    it "fail on an api request without login" do
      res = Net::HTTP.get_response URI.parse("#{@site}/v1/users/tyler")
      res.should be_a(Net::HTTPUnauthorized)
    end
  end
end