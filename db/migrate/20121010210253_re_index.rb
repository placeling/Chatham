class ReIndex < Mongoid::Migration
  def self.up
    Rake::Task['db:mongoid:create_indexes'].invoke
  end

  def self.down
  end
end