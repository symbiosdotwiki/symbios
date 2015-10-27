require 'json'
require 'net/http'
require 'shellwords'

# Title: SoundCloud plugin for Jekyll
# Author: Nick Fisher (http://spadgos.github.com)
# Edited on August, 7th 2012 by Felix Gläske
#   Added possibility to just enter the url of a ressource to get it included.
#   The old way is still working!
# Description:
#   Given a SoundCloud track, user, group, app or set, this will insert a SoundCloud HTML5 widget, with automatic Flash
#   fallback for older browsers
#
# Syntax: {% soundcloud type id [option=value [option=value [...]]]%}
# type can be one of "tracks", "groups", "users", "favorites", "apps", or "playlists".
# id should be the id of the given resource. A username can also be used in the case of "users" or "favorites"
#
# or:
#
# Syntax: {% soundcloud url [option=value [option=value [...]]]%}
# url should be the soudcloud url of the given resource.
# options are:
#
# auto_play=<true|false>
# buying=<true|false>
# download=<true|false>
# sharing=<true|false>
# show_artwork=<true|false>
# show_bpm=<true|false>
# show_comments=<true|false>
# show_playcount=<true|false>
# show_user=<true|false>
# single_active=<true|false>
# start_track=<number>
# color=<hexcode>

module Jekyll
  class SoundCloud < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      @markup = markup
      @params = Shellwords.shellwords markup
    end

    def retrieve_info(path)
      response = Net::HTTP.get_response("api.soundcloud.com","/resolve.json?client_id=YOUR_CLIENT_ID&url=" + path)
      case response
      when Net::HTTPRedirection then
        location = response['location']
        response = Net::HTTP.get_response(URI(location))
      end
      json = JSON.parse response.body
      return json
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
      #check if an url is given as argument => if yes the new method is used
      if /^http/ =~ @markup
        #parsing the "new" way with only pasing the url of the ressource
        if /(?<url>[a-z0-9\/\-\:\.]+)(?:\s+(?<options>.*))?/ =~ @markup
          info = retrieve_info(url)
          if info["errors"] == nil
            @type  = info['kind'] + 's'
            @id    = info['id']
            @options = ([] unless options) || options.split(" ")
          else
            @type = :error
            @options = []
          end
        end
      else
        #parsing the "old" way with type and id
        @type  = lookup(context, @params[0])
        @id    = lookup(context, @params[1])
        @options = []
        for i in 2..@params.length
          @options = @options.push(@params[i])
        end
      end

      if @type and @type != :error and @id
        @height = (450 unless @type == 'tracks') || 166
        @resource = (@type unless @type === 'favorites') || 'users'
        @extra = ("" unless @type === 'favorites') || '%2Ffavorites'
        @joined_options = @options.join("&amp;")
        "<iframe width=\"100%\" height=\"#{@height}\" scrolling=\"no\" frameborder=\"no\" src=\"http://w.soundcloud.com/player/?url=http%3A%2F%2Fapi.soundcloud.com%2F#{@resource}%2F#{@id}#{@extra}&amp;#{@joined_options}\"></iframe>"
      elsif @type == :error
        "Error - Sound not available!"
      else
        "Error processing input, expected syntax: {% soundcloud type id [options...] %} received: #{@markup}"
      end
    end
  end
end

Liquid::Template.register_tag('soundcloud', Jekyll::SoundCloud)

