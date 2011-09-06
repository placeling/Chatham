if (Rails.env == "production")
  raise "FUCK OFF, you're trying to reset the database in production"
  return
end

puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'SETTING UP DEFAULT USER LOGIN'
ian = User.create!(:admin =>true, :username => 'imack',
                    :email => 'ian@placeling.com', :password => 'uw2006', :password_confirmation => 'uw2006')
ian.admin = true
ian.save
puts 'New users created: ' << ian.username
user = User.create!(:admin => true, :username => 'lindsayrgwatt',
                    :email => 'lindsay@placeling.com ', :password => 'queens2001', :password_confirmation => 'queens2001')
puts 'New users created: ' << user.username
user.admin = true
user.save

puts "creating nina and application_test application"

nina = Factory.create(:nina, :user =>ian)
puts "#{nina.name} created:\n key: #{nina.key}\nsecret: #{nina.secret}"
acceptance_tests = Factory.create(:acceptance_tests, :user => ian)

puts 'creating tyler and his fav spots'
user = Factory.create(:user, :username=>'tyler')
perspective = Factory.create(:perspective, :memo =>"COSMIC", :user=>user)
perspective2 = Factory.create(:lib_square_perspective, :memo =>"LIB SQUARE", :user =>user)
