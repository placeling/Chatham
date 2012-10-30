class AddQuestionAuthorsToSubscribers < Mongoid::Migration
  def self.up
    Question.all.each do |q|
      q.subscribers << q.user.id
      q.save!
    end
  end

  def self.down
  end
end