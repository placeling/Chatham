module ApplicationHelper
  # For testing purposes on your localhost. remote_ip always returns 127.0.0.1
  #class ActionController::Request
  #  def remote_ip
  #    '24.85.231.190'
  #  end
  #end

  def current_user_location(params)
    valid_latlng = false
    if params[:lat] && params[:lng]
      valid_lat = false
      valid_lng = false
      if params[:lat]
        lat = params[:lat].to_f
        if lat != 0.0 && lat < 90.0 && lat > -90.0
          valid_lat = true
        end
      end
      if params[:lng]
        lng = params[:lng].to_f
        if lng != 0.0 && lng < 180 && lng > -180
          valid_lng = true
        end
      end
      if valid_lat && valid_lng
        valid_latlng = true
      end
    end

    if valid_latlng
      loc = [lat, lng]
    else
      if current_user && current_user.location && current_user.location != [0.0, 0.0]
        loc= current_location.location
      else
        rloc = get_location
        if rloc["remote_ip"]
          loc = [rloc["remote_ip"]["lat"], rloc["remote_ip"]["lng"]]
        else
          loc = [rloc["default"]["lat"], rloc["default"]["lng"]]
        end
      end
    end
  end

  def self.get_hostname
    if ActionMailer::Base.default_url_options[:port] && ActionMailer::Base.default_url_options[:port].to_s != "80"
      "#{ActionMailer::Base.default_url_options[:protocol]}://#{ActionMailer::Base.default_url_options[:host]}:#{ActionMailer::Base.default_url_options[:port]}"
    else
      "#{ActionMailer::Base.default_url_options[:protocol]}://#{ActionMailer::Base.default_url_options[:host]}"
    end
  end

  def simple_format_with_tags(text, html_options={}, options={})
    text = '' if text.nil?
    text = text.dup
    start_tag = tag('p', html_options, true)
    text = sanitize(text) unless options[:sanitize] == false
    text = text.to_str
    text.gsub!(/\r\n?/, "\n") # \r\n and \r -> \n
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}") # 2+ newline -> paragraph
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline -> br
    text.gsub!(/#[A-Za-z0-9]+/, '<span class="tag">\0</span>')
    text.insert 0, start_tag
    text.html_safe.safe_concat("</p>")
  end

  # haversine formula to compute the great circle distance between two points given their latitude and longitudes
  #
  # Copyright (C) 2008, 360VL, Inc
  # Copyright (C) 2008, Landon Cox
  #
  # http://www.esawdust.com (Landon Cox)
  # contact:
  # http://www.esawdust.com/blog/businesscard/businesscard.html
  #
  # LICENSE: GNU Affero GPL v3
  # The ruby implementation of the Haversine formula is free software: you can redistribute it and/or modify
  # it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.  
  #
  # This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
  # implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public 
  # License version 3 for more details.  http://www.gnu.org/licenses/
  #
  # Landon Cox - 9/25/08
  # 
  # Notes:
  #
  # translated into Ruby based on information contained in:
  #   http://mathforum.org/library/drmath/view/51879.html  Doctors Rick and Peterson - 4/20/99
  #   http://www.movable-type.co.uk/scripts/latlong.html
  #   http://en.wikipedia.org/wiki/Haversine_formula
  #
  # This formula can compute accurate distances between two points given latitude and longitude, even for 
  # short distances.

  # PI = 3.1415926535
  RAD_PER_DEG = 0.017453293 #  PI/180

  # the great circle distance d will be in whatever units R is in

  Rmiles = 3956 # radius of the great circle in miles
  Rkm = 6371 # radius in kilometers...some algorithms use 6367
  Rfeet = Rmiles * 5282 # radius in feet
  Rmeters = Rkm * 1000 # radius in meters

  #@distances = Hash.new   # this is global because if computing lots of track point distances, it didn't make
  # sense to new a Hash each time over potentially 100's of thousands of points

  def haversine_distance(lat1, lon1, lat2, lon2)
    @distances = Hash.new

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    dlon_rad = dlon * RAD_PER_DEG
    dlat_rad = dlat * RAD_PER_DEG

    lat1_rad = lat1 * RAD_PER_DEG
    lon1_rad = lon1 * RAD_PER_DEG

    lat2_rad = lat2 * RAD_PER_DEG
    lon2_rad = lon2 * RAD_PER_DEG


    a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    dMi = Rmiles * c # delta between the two points in miles
    dKm = Rkm * c # delta in kilometers
    dFeet = Rfeet * c # delta in feet
    dMeters = Rmeters * c # delta in meters

    @distances["mi"] = dMi
    @distances["km"] = dKm
    @distances["ft"] = dFeet
    @distances["m"] = dMeters

    return @distances
  end
end
