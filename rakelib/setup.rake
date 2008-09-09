require 'rubygems/source_info_cache'
require 'stringio' # for Gem::RemoteFetcher
require 'rbconfig'
require 'net/http'
require 'uri'

module Sube::Rake::Setup
  extend Sube::Rake
  extend self

  def install_gem(name, ver_requirement = ['> 0'], gem_repo = 'http://gems.rubyforge.org')
    dep = Gem::Dependency.new(name, ver_requirement)
    rb_bin = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
    if Gem::SourceIndex.from_installed_gems.search(dep).empty?
      spec = Gem::SourceInfoCache.search(dep, true, true).last
      fail "#{dep} not found in local or remote repository!" unless spec
      puts "Installing #{spec.full_name} ..."
      args = [rb_bin, '-S', 'gem', 'install', spec.name, '-v', spec.version.to_s]
      sh *args.map{ |a| a.inspect }.join(' ')
    end
  end

  def download(uri, path)
    uri = URI.parse(uri.to_s)
    path = path.to_s
    mkpath File.dirname(path)
    Net::HTTP::get_response(uri) do |res|
      File.open(path.to_s, 'wb') do |file|
        puts "Downloading #{uri} to #{file.path} ..."
        file.write res.read_body
      end
    end
  end

  def unzip(file, path)
    file = file.to_s
    path = path.to_s
    mkpath path
    begin 
      require 'zip/zip'
      require 'zip/zipfilesystem'
      Zip::ZipFile.open(file) do |source|
        source.entries.each do |entry|
          next if entry.directory?
          file = File.join(path, entry.name)
          mkpath File.dirname(file)
          source.extract(entry, file)
        end
      end
    rescue LoadError
      'unzip #{file} -d #{path}'
    end
  end

  namespace :setup do
    
    task :install_gems do 
      missing = Sube::Gem::SPEC.dependencies.select do |dep| 
        !(ENV['dev'] && dep.respond_to?(:git_uri))  ||
          Gem::SourceIndex.from_installed_gems.search(dep).empty?
      end
      missing.each do |dep| 
        if ENV['dev'] && dep.respond_to?(:git_uri)
          mkpath _('vendor')
          sh "git clone #{dep.git_uri} #{_('vendor', dep.name)}"
        else
          install_gem dep.name, dep.version_requirements, (dep.gem_repo if dep.respond_to?(:gem_repo))
        end
      end
    end

    extjs_zip = file _('vendor/ext-2.2.zip') do |t|
      download('http://extjs.com/deploy/ext-2.2.zip', t)
    end

    extjs_dir = file(_('vendor/ext-2.2') => extjs_zip) do |t|
      unzip(extjs_zip, t)
    end
    
    task :install_extjs => extjs_dir do
      mkpath _('public/extjs')
      cp File.join(extjs_dir.to_s, 'ext-2.2/adapter/ext/ext-base.js'), _('public/extjs/ext-base.js')
      cp File.join(extjs_dir.to_s, 'ext-2.2/ext-all.js'), _('public/extjs/ext-all.js')
      cp_r File.join(extjs_dir.to_s, 'ext-2.2/resources'), _('public/extjs/resources')
    end


    jwplayer_zip = file _('vendor/jw-player.zip') do |t|
      download('http://www.jeroenwijering.com/upload/mediaplayer.zip', t)
    end

    jwplayer_dir = file(_('public/jwplayer') => jwplayer_zip) do |t|
      unzip(jwplayer_zip, t)
    end

    task :install_jwplayer => jwplayer_dir

    task :install_vendor => [:install_extjs, :install_jwplayer]
    
    task :install_requirements => [:install_vendor, :install_gems]

  end
end

task :setup => ['setup:install_requirements']

