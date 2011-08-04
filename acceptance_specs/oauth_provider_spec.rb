require 'rspec'
require 'oauth'
require 'net/http'
require 'uri'

describe "OAuth Provider" do

  before(:each) do
    @key = "qqVY0ubfXOhjvu6wblBatR4H0cZGDJbbtSQ8ejp9"
    @secret = "BRtWW4PvxCKN7H4BbKe6JAeUI6YDieEsYKn0VsYX"
    @username = "tyler"
    @password = "foobar"
    @site = "http://localhost:3000"
  end

  describe "using Xauth" do
    describe "fail on an api request without proper" do
      it "password" do
        consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
        lambda {
          consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => @username, :x_auth_password => "tartus69" })
        }.should raise_error(OAuth::Unauthorized, "401 Unauthorized ")
      end

      it "username" do
        consumer = OAuth::Consumer.new(@key, @secret, :site => @site)
        lambda {
          consumer.get_access_token(nil, {}, { :x_auth_mode => 'client_auth', :x_auth_username => "blah", :x_auth_password => @password })
        }.should raise_error(OAuth::Unauthorized,  "401 Unauthorized ")
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
      }.should raise_error(OAuth::Unauthorized, "403 Forbidden ")
    end

    it "fail on an api request without login" do
      res = Net::HTTP.get_response URI.parse("#{@site}/v1/users/tyler")
      res.should be_a(Net::HTTPUnauthorized)
    end
  end
end