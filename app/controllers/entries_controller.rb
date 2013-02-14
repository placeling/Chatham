require 'google_places'

class EntriesController < ApplicationController
  before_filter :admin_required

  def place
    @blog = Blogger.where("entries._id" => BSON::ObjectId(params[:id])).first()

    @blog.entries.each do |entry|
      if entry.id.to_s == params[:id]
        @entry = entry
        break
      end
    end

    file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
    content = file.read()
    @categories = JSON(content)
    @categories.each_pair do |key, val|
      val.each_pair do |k, v|
        val[k] = k #otherwise mapping to google
      end
    end

    respond_to do |format|
      format.html
    end
  end

  def update_place
    @blog = Blogger.where("entries._id" => BSON::ObjectId(params[:id])).first()

    @entry = nil
    @blog.entries.each do |entry|
      if entry.id.to_s == params[:id]
        @entry = entry
        break
      end
    end

    valid_place = false
    if params[:reference] and params[:reference].length > 1 and params[:gid] and params[:gid].length > 1
      valid_place = true
    end

    if valid_place
      @place = Place.find_by_google_id(params[:gid])

      if @place.nil?
        gp = GooglePlaces.new
        place = gp.get_place(params[:reference])
        @place = Place.new_from_google_place(place)
        @place.save
      end

      @entry.place = @place
      @entry.location = @place.location
      @entry.save
    else
      @place = Place.new(:loc => [params[:lat].to_f, params[:lng].to_f], :name => params[:name], :street_address => params[:address], :accurate_address => params[:accurate_address], :venue_types => [params[:place_venue_type]])

      @place.address_components =JSON.parse(params[:address_components])
      @place.address_components = @place.address_components.each { |item| Hashie::Mash.new(item) }

      address_array = []
      for component in @place.address_components
        address_array << Hashie::Mash.new(component)
      end

      address_dict = GooglePlaces.getAddressDict(address_array)

      if address_dict['number'] and address_dict['street']
        @place.street_address = address_dict['number'] + " " + address_dict['street']
      elsif address_dict['street']
        @place.street_address = address_dict['street']
      end

      if address_dict['city'] and address_dict['province']
        @place.city_data = address_dict['city'] + ", " + address_dict['province']
      end

      @place.user = current_user
      @place.client_application = current_client_application unless current_client_application.nil?

      radius = 10
      gp = GooglePlaces.new
      # TODO This is hacky and ignores i18n
      @categories = CATEGORIES

      google_mapping = {}
      @categories.each do |category, components|
        components.each do |key, value|
          google_mapping[key] = value
        end
      end

      venue_type = google_mapping[@place.venue_types[0]] || @place.venue_types[0]

      unless !Rails.env.production?
        raw_place = gp.create(@place.location[0], @place.location[1], radius, @place.name, venue_type)
        @place.google_id = raw_place.id
        @place.google_ref = raw_place.reference
      end

      @place.place_type = "USER_CREATED"
      @place.save

      @entry.place = @place
      @entry.location = @place.location
      @entry.save
    end

    respond_to do |format|
      format.html { redirect_to blog_path(@blog) }
    end
  end

  def remove_place
    @blog = Blogger.where("entries._id" => BSON::ObjectId(params[:id])).first()

    @entry = nil
    @blog.entries.each do |entry|
      if entry.id.to_s == params[:id]
        @entry = entry
        break
      end
    end

    @entry.place = nil
    @entry.location = nil
    @entry.save

    respond_to do |format|
      format.html { redirect_to blog_path(@blog) }
    end
  end
end