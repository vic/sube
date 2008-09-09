require 'net/http'
require 'net/https'
require 'uri'
require 'hpricot'

module Sube

  module Http
    extend self

    def parse_uri(str, uri = nil)
      str = URI.escape(str.to_s.strip)
      "[]{}|".each_byte { |b| str.gsub!(b.chr, sprintf('%%%02X', b)) }
      puts "URI: #{str.inspect}"
      new_uri = URI.parse(str)
      if new_uri.relative? && uri
        new_uri.scheme = uri.scheme
        new_uri.host = uri.host
        new_uri.port = uri.port
        new_uri = URI.parse(new_uri.to_s)
      end
      new_uri
    end

    def media_uri(uri)
      uri = parse_uri(uri)
      media_content?(uri) || keep_vid(uri)
    end

    def media_content?(uri)
      return uri if uri.path =~ /\.(flv|mp3|mp4|wav|avi|mpe?g|wmv)$/
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.head(uri.select(:path, :query).join('?'))
      if Net::HTTPSeeOther === response
        new_uri = parse_uri(response['location'], uri)
        return media_content?(new_uri)
      end
      return uri if response.content_type =~ /audio|video|stream/
    end

    def keep_vid(uri)
      uri = URI.parse('http://keepvid.com/?url='+uri.to_s)
      response = Net::HTTP.get_response(uri)
      body = response.body
      body = Hpricot(body)
      xquery = "//div.links-c//a"
      body.search(xquery).map { |a| parse_uri(a['href'], uri) }.find { |u| media_content?(u) }
    end
    
  end

end
