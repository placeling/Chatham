class SetLowercaseUsername < Mongoid::Migration
  def self.up
    for user in User.all
      user.set_downcase_username
      user.save
    end

    Rake::Task['db:mongoid:create_indexes'].invoke
  end

  def self.down
  end
end