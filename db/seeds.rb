puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :username => 'imack', :email => 'imackinn@gmail.com', :password => 'uw2006', :password_confirmation => 'uw2006'
puts 'New user created: ' << user.username
user = User.create! :username => '
lindsayrgwatt', :email => 'lindsayrgwatt@gmail.com ', :password => 'queens2001', :password_confirmation => 'queens2001'
puts 'New user created: ' << user.username