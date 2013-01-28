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

      if @recos['places'] && @recos['places'].length > 0
        score += 1
      end

      if @recos['tours'] && @recos['tours'].length > 0
        score += 1
      end
    end

    if score >= 2
      track! :email_sent

      mail(:from => "\"Placeling\" <contact@placeling.com>", :to => @user.email, :subject => "#{@user.username}, it's almost the weekend") do |format|
        format.text
        format.html
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


    # Only send if new places to show
    if @top3.length > 0
      mail(:to => @user.email, :subject => "#{@user.username}, happy Monday", :from => "\"Placeling\" <contact@placeling.com>") do |format|
        format.html
      end
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


  end
end