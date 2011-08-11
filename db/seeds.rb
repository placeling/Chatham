puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :admin =>true, :username => 'imack', :email => 'imackinn@gmail.com', :password => 'uw2006', :password_confirmation => 'uw2006'
puts 'New users created: ' << user.username
user = User.create! :admin => true, :username => 'lindsayrgwatt', :email => 'lindsayrgwatt@gmail.com ', :password => 'queens2001', :password_confirmation => 'queens2001'
puts 'New users created: ' << user.username


puts 'creating tyler and his fav spots'
user = Factory.create(:user, :username=>'tyler')
perspective = Factory.create(:perspective, :memo =>"COSMIC", :user=>user)
perspective2 = Factory.create(:lib_square_perspective, :memo =>"LIB SQUARE", :user =>user)
