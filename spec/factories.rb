# http://railscasts.com/episodes/158-factories-not-fixtures#

Factory.define :user do |f|
  f.email 'tyler@placeling.com'
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.username 'tyler'
end


Factory.define :place do |f|
  f.location { {:x => 49.2682380, :y => -123.1525990} }
  f.name "Sophie's Cosmic Cafe"
  f.google_id "a648ca9b8af31e9726947caecfd062406dc89440"
  f.vicinity "West 4th Avenue, Vancouver"
  f.venue_types {[ "restaurant", "food", "establishment" ]}
  f.google_url "http://maps.google.com/maps/place?cid=7606348301440864605"
end