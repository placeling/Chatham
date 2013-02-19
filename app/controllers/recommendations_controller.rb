class RecommendationsController < ApplicationController
  def get_entry(blog_id, entry_id)
    blog = Blogger.find(blog_id)
    blog.entries.each do |entry|
      if entry.id.to_s == entry_id
        return entry
      end
    end

    return false
  end

  def nearby

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    geonear = BSON::OrderedHash.new()
    geonear["$near"] = [lat, lng]
    geonear["$maxDistance"] = 1

    # THIS ASSUMES THAT BLOGGERS ONLY WRITE ABOUT LOCATIONS NEAR THEM
    # COULD BE BLOGGERS IN OTHER CITIES WHO WRITE ABOUT YOUR LOCATION
    @bloggers = Blogger.where("entries.location" => geonear)
    @blogger = @bloggers.first

    @places = {}

    @popular_places = []

    # STORY 1: Pidgin
    pidgin = Place.find('511eaf0ecb20e6798d0000d7')
    story_1 = []
    story_1 << get_entry("511b1583cb20e6734d00001c", "511eae97cb20e6798d0000ce") # Vancouver Foodster
    story_1 << get_entry("511be03ecb20e63b8000000f", "511e8f1bcb20e66fe1000037") # Scout Magazine
    story_1 << get_entry("511bea0bcb20e63b8000002f", "511e84bbcb20e66b1400007f") # Urban Diner
    pidgin.entries = story_1

    @popular_places << pidgin

    # STORY 2: The Parlour Restaurant
    parlour = Place.find('511ea43fcb20e674a3000017')
    story_2 = []
    story_2 << get_entry("511bd660cb20e6369c000010", "511ea3b3cb20e674a3000014") # Ariane C Design
    story_2 << get_entry("511be0a2cb20e63b80000011", "511e8e48cb20e66fe1000032") # Modern Mix Vancouver
    story_2 << get_entry("511bea0bcb20e63b8000002f", "51227155cb20e65c34000009") # Urban Diner
    parlour.entries = story_2

    @popular_places << parlour

    # STORY 3: Unique Places
    @theme = {"label" => "Unique Places", "entries" => []}
    @theme["entries"] << get_entry("511b1da9cb20e67607000008", "511eab1ccb20e6798d000047") # Changing City
    @theme["entries"] << get_entry("511b1df8cb20e6760700000a", "511eaafacb20e6798d000042") # State of Vancouver
    @theme["entries"] << get_entry("511b1e41cb20e6760700000c", "511eaa81cb20e6798d00002d") # Illustrated Vancouver

    # Story 4: Night Life
    #night_life = []
    #night_life << get_entry("511b0b3dcb20e66f2c000003", "511eb1e7cb20e67cf6000023") # Vancouver Music Review
    #night_life << get_entry("511bee0fcb20e64255000001", "5122703acb20e65c3b000019") # Vancouverish
    #night_life << get_entry("511b0f35cb20e66f2c000011", "511e76d0cb20e65782000001") # Rain City Chronicles

    # Story 5: Arts
    #art = []
    #art << get_entry("511b10bacb20e6734d000007","511e7701cb20e6578200000d") # Gallery Gachet
    #art << get_entry("511bd595cb20e6369c00000e","511ea467cb20e674a3000018") # Van Music
    #art << get_entry("511bec82cb20e6419f000008","511e83b7cb20e66b1400003e") # Marja Rathje

    # Featured Blogger - Vancouver Is Awesome
    @blogger = Blogger.find('511b13fccb20e6734d000014')

    # River
    @river = []
    # Five featured
    @river << get_entry("511b1c8ecb20e67607000004", "511eac48cb20e6798d000065") # Vancouver Public Space
    @river << get_entry("511b1eb4cb20e6760700000e", "511eaa33cb20e6798d000021") # Price Tags
    @river << get_entry("511b1f2dcb20e67607000010", "512276c1cb20e65e5800007f") # Spacing Vancouver
    @river << get_entry("511bdfc6cb20e63b8000000d", "511e8f9acb20e66fe1000042") # Sam Sullivan
    @river << get_entry("511be530cb20e63b80000019", "511e8bedcb20e66b1400013f") # Every house has a story

    # Five random
    @river << get_entry("511b2657cb20e67b6e000008", "511ec82fcb20e60dc3000017") # Sherman's Food Blog
    @river << get_entry("511b1ac9cb20e6734d00002e", "511eacb1cb20e6798d000084") # VancityBuzz
    @river << get_entry("511b26c5cb20e67b6e00000a", "511ea61dcb20e67765000063") # Follow Me Foodie
    @river << get_entry("511be31dcb20e63e14000004", "511e8d5dcb20e66eea000019") # Your Vancouver Real Estate
    @river << get_entry("511c13b7cb20e65861000004", "511e7058cb20e655a8000002") # Hearted Girl

    #@bloggers.each do |blogger|
    #  blogger.entries.each do |entry|
    #    if entry.location && entry.created_at > 1.week.ago
    #      if entry.place_id
    #
    #        if @places.has_key? entry.place_id
    #          @places[entry.place_id] << entry
    #        else
    #          @places[entry.place_id] = [entry]
    #        end
    #      end
    #    end
    #  end
    #end

    #@popular_places = []
    #@river = []

    #@places.each do |key, value|
    #  @place = Place.find(key)
    #  if value.count > 1
    #    @place.entries = value
    #    @popular_places << @place
    #  else
    #    @river << [@place, value[0]]
    #  end
    #end

    #@popular_places.sort_by! { |place| -place.entries.count }

    #@popular_places = @popular_places.first(4)

    #@river = @river.first(10)

    respond_to do |format|
      format.json { render json: {places: @popular_places.as_json({:entries => true}), featured: @blogger.as_json({:detail_view => true}), river: @river, theme: @theme} }
    end
  end

end
