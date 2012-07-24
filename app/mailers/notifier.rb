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

  def weekly(user_id)
    @user = User.find(user_id)
    use_vanity_mailer nil

    if ab_test(:single_place_mail)
      @recos = @user.get_recommendations(1)
    else
      @recos = @user.get_recommendations
    end

    if @recos
      track! :email_sent

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

  def answer_commented(user1_id, question_id, answer_id, answer_comment_id)
    @target = User.find(user1_id)

    @question = Question.find(question_id)
    @answer = @question.answers.where(:_id => answer_id).first

    @answer_comment = @answer.answer_comments.where(:_id => answer_comment_id).first
    @user = @answer_comment.user

    mail(:to => @target.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@user.username} commented on #{@answer_comment.answer.question.title}") do |format|
      format.text
      format.html
    end
  end


  class Preview < MailView
    # Pull data from existing fixtures
    def weekly
      user = User.skip(rand(User.count)).first
      Notifier.weekly(user.id)
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

    def answer_commented
      user1 = User.find_by_username("imack")

      @question = Question.find_by_slug("wheres-the-best-brunch")
      @answer = @question.answers.where(:_id => '4ff7725a0f677376a3000004').first
      @answer_comment = @answer.answer_comments.where(:_id => "5009cead67e6e22360000520").first

      Notifier.answer_commented(user1.id, @question.id, @answer.id, @answer_comment.id)
    end


  end
end