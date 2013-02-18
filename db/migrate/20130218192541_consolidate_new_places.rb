class ConsolidateNewPlaces < Mongoid::Migration
  def self.up
    # While tagging blogs, created several new places and sometimes had to create same place multiple times
    # This migration cleans these up; the new UI of the admin tool should help eliminate this in the future
    
    # Place 1: Pidgin
    pidgin = Place.find('511eaf0ecb20e6798d0000d7')
    old_pidgin = Place.find('511e8f5bcb20e66fe100003b')
    old_pidgin_2 = Place.find('511e8519cb20e66b1400008d')
    
    # Place 2: The Parlour Restaurant
    parlour = Place.find('511ea43fcb20e674a3000017')
    old_parlour = Place.find('511e8f04cb20e66fe1000035')
    
    # Place 3: Beaucoup Bakery
    beaucoup = Place.find('511ea642cb20e6776500006a')
    old_beaucoup = Place.find('511e8ab9cb20e66eea00000c')
    
    # Place 4 : The General Public
    general_public = Place.find('511eacffcb20e6798d00008c')
    old_general_public = Place.find('511eacffcb20e6798d00008c')
    
    blogs = Blogger.all()
    blogs.each do |blog|
      entries = blog.entries
      entries.each do |entry|
        # Case 1: Pidgin
        if entry.place == old_pidgin
          entry.place = pidgin
          entry.save
          puts "Updated old_pidgin"
        elsif entry.place == old_pidgin_2
          entry.place = pidgin
          entry.save
          puts "Updated old_pidgin_2"
        # Case 2: Parlour
        elsif entry.place == old_parlour
          entry.place = parlour
          entry.save
          puts "Updated old_parlour"
        # Case 3: Beaucoup
        elsif entry.place == old_beaucoup
          entry.place = beaucoup
          entry.save
          puts "Updated old_beaucoup"
        elsif entry.place == old_general_public
          entry.place = general_public
          entry.save
          puts "Updated old_general_public"
        end
      end
    end
    
    
  end

  def self.down
  end
end