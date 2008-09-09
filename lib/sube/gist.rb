require 'mygist'

module Sube
  class Gist 
    def self.create_anonymous(snippet, file_name = nil, type = nil)
      aagent = WWW::Mechanize.new
      post_page = "http://gist.github.com"
      page = aagent.get(post_page)
      gist_form = page.forms.first
      gist_form.field("file_ext[gistfile1]").value = type if type
      gist_form.field("file_name[gistfile1]").value = file_name if file_name
      gist_form.field("file_contents[gistfile1]").value = snippet if snippet
      gist_page = aagent.submit(gist_form)
      return $1 if gist_page.uri.to_s =~ /\/(\d+)$/
    end
  end
end
