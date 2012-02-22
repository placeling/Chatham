class TempAvatarUploader < CarrierWave::Uploader::Base
  after :store, :confirm_it

  def confirm_it(file)
    puts "Store was called. We're after it now"
  end
  
  include CarrierWave::MiniMagick
  
  storage :file
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end
  
  def extension_white_list
    %w(jpg jpeg gif png)
  end
end
