class InitializePublishers < Mongoid::Migration
  def self.up

    publisher = Publisher.new
    user = User.find_by_username("gridto")

    publisher.user = user
    publisher.wellpng = "BigBox8_300x600.png"
    publisher.save

    publisher.publisher_categories.create(name: "eating", tags: "brunch, pizza, poutine, cheap,kidfriendly,latenight,grilledcheese,under10bucks,worththewait,barbecue,cookies,sushi,veganbrunch,dimsum,taketheparents", filename: "eating.png")
    publisher.publisher_categories.create(name: "drinking", tags: "sportsbar,caesar,brownliquor,cocktails", filename: "drinking.png")
    publisher.publisher_categories.create(name: "coffee", tags: "coffee", filename: "coffee.png")
    publisher.publisher_categories.create(name: "pizza", tags: "pizza", filename: "pizza.png")
    publisher.publisher_categories.create(name: "poutine", tags: "poutine", filename: "poutine.png")

    publisher.save


    publisher = Publisher.new
    user = User.find_by_username("georgiastraight")

    publisher.user = user
    publisher.footerpng = "molson_ad_small.jpg"
    publisher.wellpng = "molson_ad_vertical.jpg"
    publisher.save

    publisher.publisher_categories.create(name: "Best of Vancouver, 2012", tags: "bestofvan2011", filename: "best_of_vancouver_2.jpg")
    publisher.publisher_categories.create(name: "Golden Plates 2012", tags: "goldenplates2012", filename: "golden_plates.jpg")
    publisher.publisher_categories.create(name: "Molson Patio Finder", tags: "patio", filename: "patio_guide.jpg")
    publisher.publisher_categories.create(name: "Urban Living", tags: "urbanliving", filename: "urban_living.jpg")

    publisher.save

  end

  def self.down
    Publisher.all.destroy_all

  end
end