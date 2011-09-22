 require 'carrierwave/orm/mongoid'

CarrierWave.configure do |config|

  if Rails.env.test?
    config.storage = :file #don't want going to s3 for every test suite
  else
    config.storage = :fog

    config.fog_public     = false                                   # optional, defaults to true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
    config.fog_credentials = {
        :provider               => 'AWS',       # required
        :aws_access_key_id      => 'AKIAJ5CV27YWN6ERL32Q',       # required
        :aws_secret_access_key  => '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'       # required
    }

    if Rails.env.production? || Rails.env.staging?
      config.fog_directory  = 'chatham-production'                     # required
    elsif Rails.env.development? || Rails.env.test?
      #warning, this can be blown away at any moment
      config.fog_directory  = 'chatham-test'                     # required
    end
  end



end