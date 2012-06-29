ab_test "Answer vs Suggest" do
  description "Do we ask users to give answers or suggestions?"
  alternatives "answer", "suggestion"
  metrics :question_answer
end