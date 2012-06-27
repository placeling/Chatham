class Weekly < ActionMailer::Base
  default :from => "contact@placeling.com"

  def reccomendation(user)
    @user = user

    @place = Place.suggest_for(@user)
    @questions = Question.suggest_for(@user)


    mail(:to => @user.email, :subject => "#{@user.username}, check out #{@place.name}") do |format|
      format.text
      format.html
    end
  end


  class Preview < MailView
    # Pull data from existing fixtures
    def reccomendation
      user = User.find_by_username("imack")
      Weekly.reccomendation(user)
    end

  end

end
