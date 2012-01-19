module ApplicationHelper
  # For testing purposes on your localhost. remote_ip always returns 127.0.0.1
  class ActionController::Request
    def remote_ip
      '24.85.231.190'
    end
  end
end
