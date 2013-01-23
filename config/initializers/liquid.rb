require 'liquid/category_image'
require 'liquid/category'


Liquid::Template.register_tag('CategoryImage', CategoryImage)
Liquid::Template.register_tag('category', Category)
Liquid::Template.register_tag('Category', Category)