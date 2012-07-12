class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "[#{message.to}] #{message.subject}"
    message.to = "imackinn@gmail.com"
  end
end