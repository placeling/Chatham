# encoding: utf-8
#info about this at https://github.com/jnicklas/carrierwave, or the railscast http://railscasts.com/episodes/253-carrierwave-file-uploads

class AvatarUploader < CarrierWave::Uploader::Base

  after :store, :set_model_urls

  def set_model_urls(file)
    model.creation_environment = Rails.env
    model.cache_urls
  end

  include CarrierWave::MiniMagick

  if Rails.env.test?
    storage :file
  else
    storage :fog
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end

  # Create different versions of your uploaded files:
   version :thumb do
     process :manualcrop
     process :resize_to_fill => [160, 160]
   end

   version :main do
     process :manualcrop
     process :resize_to_fill => [960, 960]
   end
   
   process :resize_to_fit => [960, 960]
   
   def manualcrop
     return unless model.cropping?
     manipulate! do |img|
       # This bizarre code is courtesy of Minimagick: https://github.com/jnicklas/carrierwave/issues/436
       img.crop("#{model.w}x#{model.h}+#{model.x}+#{model.y}")
       img = yield(img) if block_given?
       img
     end
   end
   
   # If don't include get strange things e.g., txt files can be uploaded and resize to > 1 GB. Kills server performance
   def extension_white_list
     %w(jpg jpeg gif png)
   end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    if !Rails.env.test?
      "#{secure_token}#{File.extname(original_filename).downcase}" if original_filename
    else
      "#{secure_token}.#{file.extension}" if original_filename.present?
    end
  end

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, UUIDTools::UUID.random_create().to_s())
  end

end
