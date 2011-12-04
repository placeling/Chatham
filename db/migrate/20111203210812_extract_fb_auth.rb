class ExtractFbAuth < Mongoid::Migration
  def self.up

    for user in User.all
      if user.facebook_id
        user.authentications.create!(:provider => "facebook", :uid => user.facebook_id.to_s, :token =>user.facebook_access_token)
      end
    end
    Rake::Task['db:mongoid:create_indexes'].invoke
  end

  def self.down
  end
end