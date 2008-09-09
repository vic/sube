require 'rubygems/source_info_cache'
require 'stringio' # for Gem::RemoteFetcher
require 'rbconfig'
require 'net/http'
require 'uri'

module Sube::Rake::Setup
  extend Sube::Rake
  extend self

  def install_gem(dep)
    Gem.path.unshift _('vendor') unless Gem.path.include? _('vendor')
    gem_repo = dep.gem_repo if dep.respond_to?(:gem_repo)
    if gem_repo && !Gem.sources.include?(gem_repo)
      puts "Adding Gem source: #{gem_repo}"
      sice = Gem::SourceInfoCacheEntry.new nil, nil
      sice.refresh gem_repo, true
      Gem::SourceInfoCache.cache_data[gem_repo] = sice
      Gem::SourceInfoCache.cache.update
      Gem::SourceInfoCache.cache.flush
      Gem.sources << gem_repo
      Gem.configuration.write
    end
    gems = Gem::SourceIndex.from_installed_gems
    installer_opts = {}
    installer_opts.update({ :install_dir => _('vendor/gems') }) if ENV['dev']
    if gems.search(dep.name, dep.version_requirements).empty?
      puts "Installing dependency: #{dep}"
      require 'rubygems/dependency_installer'
      Gem::DependencyInstaller.new(installer_opts).install(dep)
    end
  end

  def download(uri, path)
    uri = URI.parse(uri.to_s)
    path = path.to_s
    mkpath File.dirname(path)
    print "Downloading #{uri} to #{path} ..."
    Net::HTTP::get_response(uri) do |res|
      File.open(path.to_s, 'wb') { |f| f.write res.read_body }
    end
    puts
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
          local_copy = "vendor/modules/#{dep.name}"
          sh 'git submodule init'
          sh "git submodule add #{dep.git_uri} #{local_copy}" rescue nil
          sh 'git submodule update'
        else
          install_gem dep
        end
      end
    end

    extjs_zip = file _('vendor/tmp/ext-2.2.zip') do |t|
      download('http://extjs.com/deploy/ext-2.2.zip', t)
    end

    extjs_dir = file(_('vendor/tmp/ext-2.2') => extjs_zip) do |t|
      unzip(extjs_zip, t)
    end
    
    task :install_extjs => extjs_dir do
      mkpath _('public/extjs')
      %w[public/extjs/ext-base.js public/extjs/ext-all.js public/extjs/resources].each { |f| rm_rf _(f) }
      cp File.join(extjs_dir.to_s, 'ext-2.2/adapter/ext/ext-base.js'), _('public/extjs/ext-base.js')
      cp File.join(extjs_dir.to_s, 'ext-2.2/ext-all.js'), _('public/extjs/ext-all.js')
      cp_r File.join(extjs_dir.to_s, 'ext-2.2/resources'), _('public/extjs/resources')
    end


    jwplayer_zip = file _('vendor/tmp/jw-player.zip') do |t|
      download('http://www.jeroenwijering.com/upload/mediaplayer.zip', t)
    end

    jwplayer_dir = file(_('public/jwplayer') => jwplayer_zip) do |t|
      rm_rf _(t.name)
      unzip(jwplayer_zip, t)
    end

    task :install_jwplayer => jwplayer_dir

    task :install_vendor => [:install_extjs, :install_jwplayer]
    
    task :install_requirements => [:install_vendor, :install_gems]

  end
end

task :setup => ['setup:install_requirements']

