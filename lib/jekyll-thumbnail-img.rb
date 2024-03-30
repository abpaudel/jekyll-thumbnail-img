require 'jekyll'
require 'mini_magick'

module Jekyll
  class JekyllThumbnailImg < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup
    end

    def render(context)
      source, width = @markup.split(" ").map(&:strip)

      # Check if the source is a Liquid variable and attempt to resolve it
      if context[source]
        source = context[source]
      end
      unless source && width
        raise "Usage: {% thumbnail_img /path/to/local/image.png 500 %}"
      end

      source_path = File.join(context.registers[:site].source, source)

      # Check if the source file exists
      unless File.exist?(source_path)
        raise "File #{source} could not be found"
      end

      # Calculate the relative path to the 'thumbnails' directory
      relative_dest_dir = File.join(File.dirname(source), "thumbnails")

      # Create the 'thumbnails' directory within the source directory
      dest_dir = File.join(context.registers[:site].source, relative_dest_dir)
      Dir.mkdir(dest_dir) unless Dir.exist?(dest_dir)

      ext = File.extname(source)
      dest = File.join(relative_dest_dir, File.basename(source, ext) + "_#{width}w#{ext}")

      # Generate the thumbnail if it doesn't exist or if the source file was modified more recently than the thumbnail
      full_dest_path = File.join(context.registers[:site].source, dest)
      if !File.exist?(full_dest_path) || File.mtime(full_dest_path) <= File.mtime(source_path)
        image = MiniMagick::Image.open(source_path)
        image.resize("#{width}x")
        image.write(full_dest_path)
        Jekyll.logger.info "JekyllThumbnailImg", "Generating: " + File.join(context.registers[:site].source, dest)
        context["site"]["static_files"] << StaticFile.new(
          context.registers[:site],
          context.registers[:site].source,
          @dir,
          dest
        )
      end
      dest
    end
  end
end

Liquid::Template.register_tag("thumbnail_img", Jekyll::JekyllThumbnailImg)
