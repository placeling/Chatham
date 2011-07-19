puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'SETTING UP DEFAULT USER LOGIN'
user = Admin.create! :username => 'imack', :email => 'imackinn@gmail.com', :password => 'uw2006', :password_confirmation => 'uw2006'
puts 'New users created: ' << user.username
user = Admin.create! :username => 'lindsayrgwatt', :email => 'lindsayrgwatt@gmail.com ', :password => 'queens2001', :password_confirmation => 'queens2001'
puts 'New users created: ' << user.username


puts 'creating tyler and his fav spots'
user = Factory.create(:user)
perspective = Factory.build(:perspective, :memo =>"COSMIC")
perspective.user = user
perspective2 = Factory.build(:lib_square_perspective, :memo =>"LIB SQUARE")
perspective2.user = user
perspective2.save!
perspective.save!
user.save!
