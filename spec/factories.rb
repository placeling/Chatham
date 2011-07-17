# http://railscasts.com/episodes/158-factories-not-fixtures#

Factory.define :user do |f|
  f.email 'tyler@placeling.com'
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.username 'tyler'
end