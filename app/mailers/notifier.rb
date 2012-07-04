class Notifier < ActionMailer::Base
  default :from => "contact@placeling.com"
  include Resque::Mailer

  def welcome(user_id)
    @user = User.find(user_id)

    if @user.loc.nil?
      @guides = []
      @guides << User.find_by_username('topspotter')
    else
      @guides = User.top_nearby(@user.loc[0], @user.loc[1], 4)
    end

    citysnapshots = User.find_by_username('citysnapshots')
    @guides.delete(citysnapshots)
    @guides.delete(@user)

    @guides = @guides[0, 3]

    mail(:to => @user.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@user.username}, welcome to Placeling") do |format|
      format.text
      format.html
    end
  end

  def follow(owner_id, new_follow_id)
    @user = User.find(owner_id)
    @target = User.find(new_follow_id)
    @type = "follow"

    mail(:to => @user.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@target.username} is now following you") do |format|
      format.text { render 'notification' }
      format.html { render 'notification' }
    end
  end

  def remark(owner_id, remarker_id, perspective_id)
    @user = User.find(owner_id)
    @target = User.find(remarker_id)
    @perspective = Perspective.find(perspective_id)
    @type = "remark"

    mail(:to => @user.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@target.username} liked your placemark") do |format|
      format.text { render 'notification' }
      format.html { render 'notification' }
    end
  end

  def weekly(user)
    @user = user

    @recos = user.get_recommendations

    if @recos
      track! :email_sent
      use_vanity_mailer user

      if @recos['questions'].length > 0

        if ab_test(:question_as_subject)
          subject = @recos['questions'].first.title
        else
          subject = "#{@user.username}, it's almost the weekend"
        end

        mail(:to => @user.email, :subject => subject, :from => "\"Placeling Weekender\" <contact@placeling.com>") do |format|
          format.text
          format.html
        end
      else
        mail(:to => @user.email, :subject => "#{@user.username}, it's almost the weekend", :from => "\"Placeling Weekender\" <contact@placeling.com>") do |format|
          format.text
          format.html
        end
      end
    end
  end


  class Preview < MailView
    # Pull data from existing fixtures
    def weekly
      user = User.skip(rand(User.count)).first
      Notifier.weekly(user)
    end

    def welcome
      user = User.find_by_username("lindsayrgwatt")
      Notifier.welcome(user.id)
    end

    def follow
      user1 = User.find_by_username("lindsayrgwatt")
      user2 = User.find_by_username("imack")

      Notifier.follow(user1.id, user2.id)
    end


  end
end