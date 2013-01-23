require 'liquid/category_image'
require 'liquid/category'


Liquid::Template.register_tag('CategoryImage', CategoryImage)
Liquid::Template.register_tag('category', Category)