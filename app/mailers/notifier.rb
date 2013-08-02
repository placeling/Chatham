class Notifier < ActionMailer::Base
  default :from => "contact@placeling.com"
  include Resque::Mailer

  def ready(user_id)
    @user = User.find(user_id)


    mail(:to => @user.email, :subject => "Your Placeling data is ready for download") do |format|
      format.text { render 'ready' }
    end
  end

end