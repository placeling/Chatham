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

    @guides_filler = Array.new(size=(3-@guides.length))

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

    @recos = @user.get_recommendations

    score = 0
    if @recos
      if @recos['guides'] && @recos['guides'].length > 0
        score += 1
      end

      if @recos['questions'] && @recos['questions'].length > 0
        score += 1
      end

      if @recos['places'] && @recos['places'].length > 0
        score += 1
      end

      if @recos['tours'] && @recos['tours'].length > 0
        score += 1
      end
    end

    if score >= 2
      track! :email_sent

      if @recos['questions'].length > 0
        if ab_test(:question_as_subject)
          subject = @recos['questions'].first.title
        else
          subject = "#{@user.username}, it's almost the weekend"
        end

        mail(:from => "\"Placeling\" <contact@placeling.com>", :to => @user.email, :subject => subject) do |format|
          format.text
          format.html
        end
      else
        mail(:from => "\"Placeling\" <contact@placeling.com>", :to => @user.email, :subject => "#{@user.username}, it's almost the weekend") do |format|
          format.text
          format.html
        end
      end
    end
  end

  def week_in_review(user_id)
    @user = User.find(user_id)
    potential = @user.week_in_review

    # Your activity for prior week
    @mine = potential[2]

    # 6 column layout in email
    if @mine['photos'].length > 0
      @mine['photos'].shuffle!
      if @mine['photos'].length > 6
        @mine['photos'] = @mine['photos'][0, 6]
      end
    end

    @mine_filler = Array.new(size=(6-@mine['photos'].length))

    scored = potential[0].sort_by { |k, v| v }.reverse

    # Calculate top 3 perspectives
    @top3 = []
    people = []

    # First see if 3 different people with perspective to show
    # Hypothesis that different people are more valuable than 3 from same person
    scored.each do |perp|
      if !people.include?(perp[0].uid)
        @top3 << perp[0]
        people << perp[0].uid
      end

      break if @top3.length >= 3
    end

    # Only then add in more from previous people
    if @top3.length < 3
      scored.each do |perp|
        if !@top3.include?(perp[0]) && ((perp[0].memo && perp[0].memo.length > 1) || perp[0].pictures.length > 0)
          @top3 << perp[0]
          if @top3.length == 3
            break
          end
        end
      end
    end

    @top3_filler = Array.new(size=(3-@top3.length))

    # Additionally show up to six photos
    @pics = []

    scored.each do |perp|
      if !@top3.include?(perp[0])
        if perp[0].pictures.length > 0
          perp[0].pictures.each do |pic|
            if !pic.deleted
              @pics << {'perp' => perp[0], 'pic' => pic}
            end
          end
        end
      end
    end

    # 6 column layout in email
    if @pics.length > 0
      @pics.shuffle!
      if @pics.length > 6
        @pics = @pics[0, 6]
      end
    end

    @pics_filler = Array.new(size=(6-@pics.length))

    # Guides
    # Bias to favour guides with profile pictures
    @guides = []
    no_photos = []
    potential[1].each do |guide|
      if guide.thumb_cache_url
        @guides << guide
      else
        no_photos << guide
      end
    end

    if @guides.length > 3
      @guides.shuffle!
      @guides = @guides[0, 3]
    end

    if @guides.length < 3
      no_photos.each do |guide|
        @guides << guide
        if @guides.length == 3
          break
        end
      end
    end

    @guides_filler = Array.new(size=(3-@guides.length))

    # Questions
    @questions = potential[3]
    if @questions.length > 3
      @questions.shuffle!
      @questions = @questions[0, 3]
    end

    # Only send if new places to show
    if @top3.length > 0
      mail(:to => @user.email, :subject => "#{@user.username}, happy Monday", :from => "\"Placeling\" <contact@placeling.com>") do |format|
        format.html
      end
    end
  end

  def question_answered(user1_id, question_id, answer_id, user2_id)
    @target = User.find(user1_id)

    @question = Question.find(question_id)
    @answer = @question.answers.where(:_id => answer_id).first
    @user

    mail(:to => @target.email, :from => "\"Placeling\" <contact@placeling.com>", :subject => "#{@answer.place.name} was suggested for #{@question.title}") do |format|
      format.text
      format.html
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

    def week_in_review
      user = User.skip(rand(User.count)).first
      Notifier.week_in_review(user.id)
    end

    def welcome
      user = User.skip(rand(User.count)).first
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

    def question_answered
      user1 = User.find_by_username("imack")

      @question = Question.find_by_slug("wheres-the-best-brunch")
      @answer = @question.answers.where(:_id => '4ff7725a0f677376a3000004').first

      Notifier.question_answered(user1.id, @question.id, @answer.id, nil)
    end


  end
end