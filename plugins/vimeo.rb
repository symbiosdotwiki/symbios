module Jekyll
  class Vimeo < Liquid::Tag

    def initialize(name, markup, tokens)
      super
      @params = Shellwords.shellwords markup
    end

    def lookup(context, name)
      return nil if name == nil
      return name if name.kind_of?(Array)
      lookup = context
      name.split(".").each { |value| lookup = lookup[value] }
      return name if lookup == nil
      lookup
    end

    def render(context)
    	@id = lookup(context, @params[0])
      %(<div class="embed-video-container"><iframe src="https://player.vimeo.com/video/#{@id}" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen> </iframe></div>)
    end
  end
end

Liquid::Template.register_tag('vimeo', Jekyll::Vimeo)