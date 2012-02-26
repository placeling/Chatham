module ApplicationHelper
  # For testing purposes on your localhost. remote_ip always returns 127.0.0.1
  #class ActionController::Request
  #  def remote_ip
  #    '24.85.231.190'
  #  end
  #end
  
  def simple_format_with_tags(text, html_options={}, options={})
    text = '' if text.nil?
    text = text.dup
    start_tag = tag('p', html_options, true)
    text = sanitize(text) unless options[:sanitize] == false
    text = text.to_str
    text.gsub!(/\r\n?/, "\n") # \r\n and \r -> \n
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}") # 2+ newline -> paragraph
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline -> br
    text.gsub!(/#[A-Za-z0-9]+/, '<span class="tag">\0</span>')
    text.insert 0, start_tag
    text.html_safe.safe_concat("</p>")
  end
end
