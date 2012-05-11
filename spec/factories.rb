# http://railscasts.com/episodes/158-factories-not-fixtures#
# Vancouver Public Library: 49.279484, -123.115349
# Sophie's Cosmic Cafe: 49.2682380,-123.1525990

FactoryGirl.define do

  factory :oauth_nonce_one, :class => OauthNonce  do
    nonce "a_nonce"
    timestamp 1
  end

  factory :oauth_nonce_two, :class => OauthNonce  do
    nonce "b_nonce"
    timestamp 2
  end

end

FactoryGirl.define do

  factory :oauth_token_one, :class => OauthToken  do
    association :user, :factory => :user
    association :client_application, :factory => :client_application_one
    token "one"
    secret "MyString"
  end

  factory :oauth_token_two, :class => OauthToken  do
    association :user, :factory => :user
    association :client_application, :factory => :client_application_one
    token "two"
    secret "MyString"
  end

  factory :access_token, :class => AccessToken  do
    association :user, :factory => :user
    association :client_application, :factory => :client_application_one
    token "two"
  end


end

FactoryGirl.define do

  factory :client_application, :class => ClientApplication  do
    name "MyString"
    url "http://test.com"
    support_url "http://test.com/support"
    callback_url "http://test.com/callback"
    key "one_key"
    secret "MyString"
    description "This is the first test application"
  end

  factory :nina, :class => ClientApplication  do
    name "Nina"
    url "http://localhost:3000"
    support_url "http://localhost:3000"
    callback_url "http://localhost:3000"
    description "This is the flagship iPhone application for Placeling"
  end

  factory :acceptance_tests, :class => ClientApplication  do
    name "Acceptance Specs"
    url "http://localhost:3000"
    support_url "http://localhost:3000"
    callback_url "http://localhost:3000"
    description "This for the live acceptance tests"
  end


  factory :client_application_two, :class => ClientApplication  do
    name "MyString"
    url "http://test.com"
    support_url "http://test.com/support"
    callback_url "http://test.com/callback"
    key "two_key"
    secret "MyString"
    description "This is the second test application"
  end

end


FactoryGirl.define do
  factory :maven, :class => User do
    username "Gladwell"
    sequence(:email) { "gladwell@placeling.com" }
    password "foobar"
    fullname "Malcolm Gladwell"
    password_confirmation { |u| u.password }
    location { [49.2642380,-123.1625990] }
    city "New York, NY, USA"
    description "I am the test user interesting things going on"
  end

  factory :user do
    sequence(:username) { |n| "tyler#{n}" }
    sequence(:email) { |n| "tyler#{n}@placeling.com" }
    password "foobar"
    fullname "Tyler Durden"
    password_confirmation { |u| u.password }
    location { [49.2642380,-123.1625990] }
    city {"Vancouver, BC, Canada"}
    description "I am the test user with no admin privileges, and nothing interesting"
    confirmed_at {Time.now}
  end

  factory :admin, :class =>User do
    username "Admin"
    email  "admin@placeling.com"
    password "foobar"
    fullname "Placeling Administrator"
    password_confirmation { |u| u.password }
    location { [49.2642380,-123.1625990] }
    city {"Vancouver, BC, Canada"}
    description "I am a placeling administrator"
    admin true
    confirmed_at {Time.now}
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
    google_ref "CnRqAAAAupFuI8pPDPHvtmu8wLqOJIIw7MjQnU0AuOSciRaYv315ctp_J0A3Wa480MLdw2S4TZ4bz6tZkDkywesF2IlpDHYxEGOC4yZ7s86XaQkFmMwsddoRjOjGPfBefkHM9oIjbATDZquo1enEMluCCLIkfxIQ_mHe2TJeJCh7C1EKeLD5DRoU-Xa0MoV9FRpW-8u_lcOUrXM5XIw"
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
  
  factory :new_place, :class => Place do
    location { [49.28199, -123.10814]}
    name "GrowLab Test Place"
    venue_types {[ "other"]}
  end
  
  factory :invalid_google_id_place, :class => Place do
    location {[45.0, 45.0]}
    name "A Fake Place"
    google_id "Fake1234"
    venue_types {["other"]}
  end
end


FactoryGirl.define do

  factory :picture do
    image File.open(File.join(Rails.root, 'spec', 'fixtures', 'IMG_0288.JPG') )
  end
end

FactoryGirl.define do
  factory :perspective do
    association :place, :factory => :place
    association :user, :factory => :user
    location { [49.2642380,-123.1625990] }
    accuracy 500
    memo "This is the best place for #breakfast in kits, usually a lineup on weekend mornings though"
  end

  factory :lib_square_perspective, :class => Perspective do
    association :place, :factory => :lib_square
    association :user, :factory => :user
    location { [49.279430, -123.115334] }
    accuracy 500
    memo "Yet another #donnelly bar"
  end
end