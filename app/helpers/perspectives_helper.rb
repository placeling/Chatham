module PerspectivesHelper
  # Turns array of photos into a 3 column mosaic
  def mosaic_3(photos)
    photo_values = []
    clean_photos = []
    photos.each do |photo|
      if !photo.deleted
        clean_photos << photo
      end
    end
    
    # Randomize order purely so that page changes; aesthetic, not functional, reason
    clean_photos.shuffle!
    
    widths = [] # Holds number of columns each image should span
    length = clean_photos.length
    
    base = length / 3
    modulus = length % 3
    
    if base > 0
      i = 0
      while i < base
        temp = rand(1..10)
        if temp == 1
          widths += [1, 2, 3]
        elsif temp == 2
          widths += [2, 1, 3]
        else
          widths += [1, 1, 1]
        end
        i += 1
      end
    end
    
    if modulus == 2
      temp = rand(1..10)
      if temp <= 2
        widths += [3, 3]
      elsif temp <= 6
        widths += [2, 1]
      else
        widths += [1, 2]
      end
    elsif modulus == 1
      widths << 3
    end
    
    # convert widths to urls
    widths.each_with_index do |item, i|
      if item == 1
        photo_values[i] = {
          "main" => clean_photos[i].main_url,
          "mini" => clean_photos[i].mosaic_3_1_url
        }
      elsif item == 2
        photo_values[i] = {
          "main" => clean_photos[i].main_url,
          "mini" => clean_photos[i].mosaic_3_2_url
        }
      elsif item == 3
        photo_values[i] = {
          "main" => clean_photos[i].main_url,
          "mini" => clean_photos[i].mosaic_3_3_url
        }
      else
        puts "Shouldn't be here!"
      end
    end
    
    return photo_values
  end
end
