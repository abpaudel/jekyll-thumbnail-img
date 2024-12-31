require 'jekyll'
require 'mini_magick'

module Jekyll
  class JekyllThumbnailImg < Liquid::Tag
    @@pending = [] # thumbnails to be generated

    def initialize(tag_name, markup, tokens)
      super
      @markup = markup
    end

    def render(context)
      source, width = @markup.split.map(&:strip)
      # resolve liquid vars
      source = context[source] if context[source]
      width = context[width] if context[width]

      raise "Usage: {% thumbnail_img /path/to/image.png 500 %}" unless source && width
      raise "File #{source} not found" unless File.exist?(File.join(context.registers[:site].source, source))

      # Queue thumbnail for generation
      dest = File.join(File.dirname(source), "thumbnails", "#{File.basename(source, '.*')}_#{width}w#{File.extname(source)}")
      @@pending << {
        source: File.join(context.registers[:site].source, source),
        dest: File.join(context.registers[:site].dest, dest),
        width: width
      }

      dest
    end

    def self.generate_thumbnails(site)
      @@pending.each do |thumb|
        FileUtils.mkdir_p(File.dirname(thumb[:dest]))
        if !File.exist?(thumb[:dest]) || File.mtime(thumb[:dest]) <= File.mtime(thumb[:source])
          Jekyll.logger.info "JekyllThumbnailImg:", "Generating: #{thumb[:dest].sub(site.dest + '/', '')}"
          MiniMagick::Image.open(thumb[:source]).resize("#{thumb[:width]}x").write(thumb[:dest])
        end
      end
      @@pending.clear
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::JekyllThumbnailImg.generate_thumbnails(site)
end

Liquid::Template.register_tag("thumbnail_img", Jekyll::JekyllThumbnailImg)
