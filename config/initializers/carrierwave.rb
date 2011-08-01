 require 'carrierwave/orm/mongoid'

CarrierWave.configure do |config|

  if Rails.env.production? || Rails.env.staging?
    # TODO
    # probably best for amazone s3 to be best here
    config.storage = :file
  elsif Rails.env.development? || Rails.env.test?
    config.storage = :file
  end

end