require 'spec_helper'

describe Suggestion do
  it "can be created" do
    suggestion = Factory.create(:suggestion)

    suggestion.place.should_not be_nil
    suggestion.sender.should_not be_nil
    suggestion.receiver.should_not be_nil
  end

  it "can be found" do
    suggestion = Factory.create(:suggestion)

    suggestion = Suggestion.find(suggestion.id)
    suggestion.should_not be_nil
  end

  it "can be found for a user" do
    user = Factory.create(:user)
    suggestion = Factory.create(:suggestion, :receiver => user)

    suggestions = Suggestion.find_suggested_for_user(user)
    suggestions.count.should == 1
  end

end
