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

end