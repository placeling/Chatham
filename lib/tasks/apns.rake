
namespace "apns" do

  desc "Send Ian a message"
  task :message_ian => :environment do
    ian = User.find_by_username("imack")
    APNS.send_notification( ian.ios_notification_token, "BLAH")
  end

end