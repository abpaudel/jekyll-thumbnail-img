Gem::Specification.new do |spec|
  spec.name          = 'jekyll-thumbnail-img'
  spec.version       = '0.1.2'
  spec.authors       = ['Abhishek Paudel']
  spec.summary       = 'A Jekyll plugin to generate image thumbnails with specified width.'
  spec.homepage      = 'https://github.com/abpaudel/jekyll-thumbnail-img'
  spec.license       = 'MIT'
  spec.files         = ['lib/jekyll-thumbnail-img.rb']
  spec.add_dependency 'jekyll'
  spec.add_dependency 'mini_magick'
end
