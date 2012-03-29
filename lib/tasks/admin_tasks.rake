
namespace "db" do

  task :reload => [:drop, :download_and_install]

  desc "Drops the database for mongodb"
  task :drop do
    if (Rails.env == "production")
      raise "FUCK OFF, you're trying to reset the database in production"
      return
    end
    db = Mongoid::Config.master
    conn = db.connection

    puts "DROPPING MONGO DATABASE NAMED #{db.name}"
    conn.drop_database( db.name )
  end

  desc "Reloads the database based the the latest backup from production"
  task :download_and_install do
    if (Rails.env == "production")
      raise "FUCK OFF, you're trying to reset the database in production"
      return
    end
    db = Mongoid::Config.master

    if File.exists?('/tmp/mongodb-latest.tgz')
      file = File.new('/tmp/mongodb-latest.tgz', 'r')
      puts "current file in temp is timestamp: " + file.mtime.to_s
    end

    if file.nil? or file.mtime < 1.day.ago
      puts "getting new backup"
      puts `scp -P 11235 ubuntu@beagle.placeling.com:/chatham_backups/latest/mongodb-latest.tgz /tmp/mongodb-latest.tgz`
      puts `rm -rf /tmp/MONGOBACKUP`
      puts `mkdir /tmp/MONGOBACKUP`
      puts `tar -C /tmp/MONGOBACKUP -xzvf /tmp/mongodb-latest.tgz`
    end

    # this is a little hacky, but works for now
    puts `/usr/local/mongodb/bin/mongorestore -h #{db.connection.host} -d chatham_#{Rails.env} /tmp/MONGOBACKUP/*/chatham_production/`
    Rake::Task["db:mongoid:create_indexes"].invoke
  end
end
