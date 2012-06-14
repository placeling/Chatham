module QuestionsHelper

  def upvote_icon( answer, current_user, session_options )

    if current_user
      if answer.voters.has_key? current_user.id.to_s
        return asset_path('starred.png')
      else
        return asset_path('unstarred.png')
      end
    else
      session_id = session_options[:id]
      if answer.voters.has_key? session_id.to_s
        return asset_path('starred.png')
      else
        return asset_path('unstarred.png')
      end
    end

  end

  def map_url( question )
    url = "https://maps.googleapis.com/maps/api/staticmap?center=#{ question.location[0]},#{ question.location[1] }&zoom=11&size=258x198&sensor=false"

    question.answers.each do |answer|
      url += "&markers=icon:http://www.placeling.com/images/marker.png%7Ccolor:red%7C#{answer.place.location[0]},#{answer.place.location[1]}" unless answer.new_record?
    end
    return url
  end

end