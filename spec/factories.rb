# http://railscasts.com/episodes/158-factories-not-fixtures#

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
end

FactoryGirl.define do
  factory :perspective do
    location { [49.2642380,-123.1625990] }
    radius 500
    memo "this place is da bomb"
  end
end