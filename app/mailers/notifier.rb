class Notifier < ActionMailer::Base
  default :from => "contact@placeling.com"
  include Resque::Mailer

  def remark(user_id)
    @user = User.find(owner_id)
    @target = User.find(remarker_id)
    @perspective = Perspective.find(perspective_id)
    @type = "remark"

    mail(:to => @user.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@target.username} liked your placemark") do |format|
      format.text { render 'notification' }
      format.html { render 'notification' }
    end
  end


  class Preview < MailView

    def welcome
      user = User.skip(rand(User.count)).first
      Notifier.welcome(user.id)
    end

    def follow
      user1 = User.find_by_username("lindsayrgwatt")
      user2 = User.find_by_username("imack")

      Notifier.follow(user1.id, user2.id)
    end


  end
end