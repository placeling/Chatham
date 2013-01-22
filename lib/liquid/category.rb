class Category < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @rand = markup.to_i
  end

  def render(context)
    if rand(@rand) == 0
      super
    else
      ''
    end
  end
end

Liquid::Template.register_tag('category', Category)