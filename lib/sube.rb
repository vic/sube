require 'json'
require 'builder'
require 'sube/gist'
require 'sube/http'

module Sube

  VERSION = '0.1 Alpha'
  APP_TITLE = "SubE - Online Subtitle Editor (#{VERSION})"

  get('/') { haml :'index.html' }
  get('/index.html?') { haml :'index.html' }

  get '/preview/:winId/:unique' do
    content_type 'application/xml'
    winId = params['winId']
    session['ttaf1/'+winId]
  end

  post '/preview/:winId' do
    winId = params['winId']
    session['ttaf1/'+winId] = records_to_ttaf1(params['records'])
    params['captionsURI'] = '/preview/'+winId+'/'+uuid
    erb :'/js/sube/save_preview.js'
  end
    
  post '/save/gist/anon' do
    records = records_to_ttaf1(params['records'])
    gist = Gist.create_anonymous(records, nil, ".xml")
    params["gist"] = gist
    erb :"/save.html"
  end

  get '/doc/*.html' do
    haml request.path_info.to_sym
  end

  get "/*.json" do
    erb request.path_info.to_sym
  end

  post "/*.json" do
    content_type 'application/json'
    erb request.path_info.to_sym
  end

  get '/*.js' do
    content_type 'text/javascript'
    erb request.path_info.to_sym
  end

  module HelperMethods

    def uuid
      Time.now.strftime('%s').to_s
      # @uuid ||= UUID.new
      # @uuid.generate
    end

    def records_to_ttaf1(records)
      records = JSON.load(records)
      builder = Builder::XmlMarkup.new(:indent => 2)
      builder.instruct!
      builder.tt('xml:lang'=>"en", 'xmlns:tts'=>"http://www.w3.org/2006/10/ttaf1#styling", 'xmlns'=>"http://www.w3.org/2006/10/ttaf1") do
        builder.head { }
        builder.body do 
          builder.div(:"xml:id" => "captions") do 
            records.each do |record|
              builder.p(:begin => record['from'], :end => record['to']) do 
                builder.cdata!(record['text'].gsub(/[\n\r]/, '<br/>'))
              end
            end
          end
        end
      end
    end
  end

  class ::Sinatra::EventContext
    include HelperMethods
  end

  helpers do
    def path_to(path)
      url = request.scheme + "://"
      url << request.host
      if request.scheme == 'https' && request.port != 443 ||
         request.scheme == 'http' && request.port != 80
        url << ":#{request.port}"
      end
      url << path
      url
    end
  end

end



