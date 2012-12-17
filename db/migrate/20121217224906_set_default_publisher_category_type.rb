class SetDefaultPublisherCategoryType < Mongoid::Migration
  def self.up

    Publisher.all.each do |pub|
      pub.publisher_categories.each do |pubcat|
        pubcat.update_attribute(:_type, "TagSearchModule")
        pubcat.save
      end
    end
  end

  def self.down
  end
end