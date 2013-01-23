class Category < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    markup_array = markup.split(",")
    @slug = markup_array[0].strip
    @html_id = markup_array[1]
    @html_class = markup_array[2]
  end

  def render(context)
    publisher = context.environments.first["publisher"]

    pubcat = publisher.category_for(@slug)

    "<a href='/category/#{pubcat.slug}' #{('id="'+@html_id.strip+'"') unless @html_id.nil?} #{('class="'+@html_class.strip+'"') unless @html_class.nil?} />" + super + "</a>"
  end
end