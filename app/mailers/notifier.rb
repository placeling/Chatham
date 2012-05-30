class Notifier < ActionMailer::Base
  default :from => "contact@placeling.com"
  include Resque::Mailer
  
  def welcome(user_id)
    @user = User.find( user_id )
    
    @guides = []
    
    if @user.loc
      counter = 0
      nearby = User.where(:loc=>{"$near"=>user.loc,"$maxDistance"=>"0.05"}).desc(:pc, :username).excludes(:username=>'citysnapshots')
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
    
    mail(:to => @user.email, :from => "contact@placeling.com") do |format|
      format.text
      format.html
    end
  end
end
