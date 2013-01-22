class CategoryUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  if Rails.env.test?
    storage :file
  else
    storage :fog
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/publisher_category/#{model.id}"
  end

  # Create different versions of your uploaded files:

  version :thumb do
    process :resize_to_fit => [150, 100]
  end

  def default_url
    "/assets/publishers/category_default.jpg" # asset_path("publishers/category_default.jpg")
  end

  # If don't include get strange things e.g., txt files can be uploaded and resize to > 1 GB. Kills server performance
  def extension_white_list
    %w(jpg jpeg gif png bmp)
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