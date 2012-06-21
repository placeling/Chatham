require "spec_helper"

describe "Quick Picks" do

  it "everything following" do
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    user3 = Factory.create(:user)
    user4 = Factory.create(:user) #control user

    user.follow( user2 )
    user.follow( user3 )

    place = Factory.create(:lib_square)
    place2 = Factory.create(:new_place)
    place3 = Factory.create(:place)

    perspective = Factory.create(:perspective, :memo=>"one", :place =>place, :user =>user2)
    perspective2 = Factory.create(:perspective, :memo=>"two", :place =>place, :user =>user3)
    perspective3 = Factory.create(:perspective, :memo=>"three", :place =>place2, :user =>user3)

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    get suggested_places_path, {
      :format => 'json',
      :lat => '49.282049',
      :lng => '-123.107772',
      :query_type => 'following'
    }

    response.status.should be(200)

    showPlace = JSON.parse( response.body )
    pp showPlace
    showPlace['suggested_places'].count.should == 2

  end

  it "everything popular" do
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    user3 = Factory.create(:user)
    user4 = Factory.create(:user) #control user

    user.follow( user2 )
    user.follow( user3 )

    place = Factory.create(:lib_square)
    place2 = Factory.create(:new_place)

    place3 = Factory.create(:lib_square, :name => "secondary place")
    place4 = Factory.create(:lib_square, :name => "ternary place")
    place5 = Factory.create(:lib_square, :name => "quadranary place")

    perspective = Factory.create(:perspective, :memo=>"one", :place =>place, :user =>user2)
    perspective2 = Factory.create(:perspective, :memo=>"two", :place =>place2, :user =>user3)
    perspective3 = Factory.create(:perspective, :memo=>"three", :place =>place3, :user =>user4)
    perspective4 = Factory.create(:perspective, :memo=>"three", :place =>place4, :user =>user2)
    perspective5 = Factory.create(:perspective, :memo=>"three", :place =>place5, :user =>user3)

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    get suggested_places_path, {
      :format => 'json',
      :lat => '49.282049',
      :lng => '-123.107772',
      :query_type =>'popular'
    }

    response.status.should be(200)

    showPlace = JSON.parse( response.body )
    showPlace['suggested_places'].count.should == 5

  end


end