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
    url = "https://maps.googleapis.com/maps/api/staticmap?zoom=12&size=258x198&sensor=false"

    tally = 0
    lat = 0.0
    lng = 0.0
    question.answers.order_by([[:upvotes, :desc]]).limit(5).each do |answer|
      unless answer.new_record?
        url += "&markers=icon:http://www.placeling.com/images/marker.png%7Ccolor:red%7C#{answer.place.location[0]},#{answer.place.location[1]}"
        tally += 1
        lat += answer.place.location[0]
        lng += answer.place.location[1]
      end

    end

    if tally > 1
      url += "&center=#{ lat/tally },#{ lng/tally }"
    else
      url += "&center=#{ question.location[0]},#{ question.location[1] }"
    end
    return url
  end

end