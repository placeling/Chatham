# http://railscasts.com/episodes/158-factories-not-fixtures#
# Vancouver Public Library: 49.279484, -123.115349
# Sophie's Cosmic Cafe: 49.2682380,-123.1525990



FactoryGirl.define do
  factory :user do
    email 'tyler@placeling.com'
    password "foobar"
    password_confirmation { |u| u.password }
    username 'tyler'
  end
end


FactoryGirl.define do
  factory :place do
    location { [49.2682380,-123.1525990] }
    name "Sophie's Cosmic Cafe"
    google_id "a648ca9b8af31e9726947caecfd062406dc89440"
    vicinity "West 4th Avenue, Vancouver"
    venue_types {[ "restaurant", "food", "establishment" ]}
    google_url "http://maps.google.com/maps/place?cid=7606348301440864605"
    place_type "GOOGLE_PLACE"
  end


  # This will use the User class (Admin would have been guessed)
  factory :lib_square, :class => Place do
    location { [49.279960,-123.1144710] }
    name "Library Square Public House"
    google_id "3f8f0485acd6ee0b9bad966106e47517045841d8"
    vicinity "West Georgia Street, Vancouver"
    venue_types {[ "bar", "food", "establishment" ]}
    google_url "http://maps.google.com/maps/place?cid=3254539966235120932"
    place_type "GOOGLE_PLACE"
  end

end

FactoryGirl.define do
  factory :perspective do
    association :place, :factory => :place
    location { [49.2642380,-123.1625990] }
    accuracy 500
    memo "this place is da bomb"
  end

  factory :lib_square_perspective, :class => Perspective do
    association :place, :factory => :lib_square
    location { [49.279430, -123.115334] }
    accuracy 500
    memo "I want to like this place but it can get a little douchy"
  end
end