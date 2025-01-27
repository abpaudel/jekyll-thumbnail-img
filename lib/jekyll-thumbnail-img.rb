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

      site = context.registers[:site]
      raise "File #{source} not found" unless File.exist?(File.join(site.source, source))

      # Queue thumbnail for generation
      thumb_filename = "#{File.basename(source, '.*')}_#{width}w#{File.extname(source)}"
      thumb_dir = File.join('.thumbnails', File.dirname(source), 'thumbnails')
      dest = File.join(File.dirname(source), "thumbnails", thumb_filename)

      # Add to pending list if not already there
      @@pending << {
        source: File.join(site.source, source),
        cache: File.join(site.source, thumb_dir, thumb_filename),
        dest: File.join(site.dest, dest),
        width: width
      } unless @@pending.any? { |thumb| thumb[:source] == source && thumb[:width] == width }

      dest
    end

    def self.generate_thumbnails(site)
      @@pending.each do |thumb|
        FileUtils.mkdir_p(File.dirname(thumb[:cache]))
        FileUtils.mkdir_p(File.dirname(thumb[:dest]))

        # Generate thumbnail if not already generated or source is newer
        if !File.exist?(thumb[:cache]) || File.mtime(thumb[:cache]) <= File.mtime(thumb[:source])
          Jekyll.logger.info "JekyllThumbnailImg:", "Generating: #{thumb[:dest].sub(site.dest + '/', '')}"
          MiniMagick::Image.open(thumb[:source]).resize("#{thumb[:width]}x").write(thumb[:cache])
        end

        # Copy from cache to destination
        FileUtils.cp(thumb[:cache], thumb[:dest])
      end
      @@pending.clear
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::JekyllThumbnailImg.generate_thumbnails(site)
end

Liquid::Template.register_tag("thumbnail_img", Jekyll::JekyllThumbnailImg)
