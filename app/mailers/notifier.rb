class Notifier < ActionMailer::Base
  default :from => "contact@placeling.com"
  include Resque::Mailer
  
  def welcome(user_id)
    @user = User.find( user_id )
    
    @guides = []
    
    if @user.loc
      counter = 0
      nearby = User.where(:loc=>{"$near"=>@user.loc,"$maxDistance"=>"0.05"}).desc(:pc, :username).excludes(:username=>'citysnapshots')
      nearby.each do |candidate|
        if candidate.id != @user.id
          @guides << candidate
          counter += 1
          if counter == 3
            break
          end
        end
      end
    end    
    
    mail(:to => @user.email, :from => "contact@placeling.com", :subject =>"#{@user.username}, welcome to Placeling") do |format|
      format.text
      format.html
    end
  end
  
  def follow(owner_id, new_follow_id)
    @user = User.find(owner_id)
    @target = User.find(new_follow_id)
    @type = "follow"
    
    mail(:to => @user.email, :from =>"contact@placeling.com", :subject => "#{@target.username} is now following you") do |format|
      format.text {render 'notification'}
      format.html {render 'notification'}
    end
  end
  
  def remark(owner_id, remarker_id, perspective_id)
    @user = User.find(owner_id)
    @target = User.find(remarker_id)
    @perspective = Perspective.find(perspective_id)
    @type = "remark"
    
    mail(:to => @user.email, :from =>"contact@placeling.com", :subject => "#{@target.username} liked your placemark") do |format|
      format.text {render 'notification'}
      format.html {render 'notification'}
    end
  end
end