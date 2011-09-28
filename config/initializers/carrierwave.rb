 require 'carrierwave/orm/mongoid'

CarrierWave.configure do |config|
    config.fog_public     = true         # optional, defaults to true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
    config.fog_credentials = {
        :provider               => 'AWS',       # required
        :aws_access_key_id      => 'AKIAJ5CV27YWN6ERL32Q',       # required
        :aws_secret_access_key  => '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'       # required
    }

   if Rails.env.development?
      config.fog_directory  = 'chatham-test'                     # required
   else
      config.fog_directory  =  'chatham-production'                    # required
   end

end