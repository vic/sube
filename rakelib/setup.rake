require 'rubygems/source_info_cache'
require 'stringio' # for Gem::RemoteFetcher
require 'rbconfig'
require 'net/http'
require 'uri'

module Sube::Rake::Setup
  extend Sube::Rake
  extend self

  attr_accessor :gem_home

  def gem_config
    ENV['GEM_HOME'] = @gem_home = _('vendor/gems')
    Gem.use_paths(gem_home, [gem_home, Gem.path])
  end

  def install_gem(dep)
    gem_repo = dep.gem_repo if dep.respond_to?(:gem_repo)
    if gem_repo && !Gem.sources.include?(gem_repo)
      puts "Adding Gem source: #{gem_repo}"
      sice = Gem::SourceInfoCacheEntry.new nil, nil
      sice.refresh gem_repo, true
      Gem::SourceInfoCache.cache_data[gem_repo] = sice
      Gem::SourceInfoCache.cache.update
      Gem::SourceInfoCache.cache.flush
      Gem.sources << gem_repo
      #Gem.configuration.write
    end
    gems = Gem::SourceIndex.from_installed_gems
    installer_opts = {:ignore_dependencies => false}
    installer_opts.update({ :install_dir => gem_home })
    if gems.search(dep.name, dep.version_requirements).empty?
      puts "Installing dependency: #{dep} on #{gem_home}"
      require 'rubygems/dependency_installer'
      begin
        Gem::DependencyInstaller.new(installer_opts).install(dep.name, dep.version_requirements)
      rescue Gem::GemNotFoundException => e
        puts e
      end
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
      sh "unzip #{file} -d #{path}"
    end
  end

  def git_clone(dep)
    mkpath _('vendor/modules')
    local_copy = "vendor/modules/#{dep.name}"
    begin
      sh "git clone #{dep.git_uri} #{local_copy}"
      local_copy
    rescue => e
      puts e
    end
  end

  namespace :setup do

    desc "Clone other git projects on vendor/modules"
    task :git_clone, :only do |t, args|
      only = %r[#{args[:only]}] if args[:only]
      gits = Sube::Gem::SPEC.dependencies.select { |dep| dep.respond_to?(:git_uri) }
      gits = gits.select { |dep| only === dep.name } if only
      gits.each { |dep| git_clone(dep) }
    end

    desc "Install dependency gems"
    task :install_gems, :only, :nogit do |t, args|
      gem_config
      only = %r[#{args[:only]}] if args[:only]
      missing = Sube::Gem::SPEC.dependencies.select { |dep| Gem::SourceIndex.from_installed_gems.search(dep).empty? }
      missing = missing.select { |dep| only === dep.name } if only
      missing.delete_if { |dep| dep.respond_to?(:git_uri) } if args[:nogit]
      missing.each { |dep| install_gem dep }
    end

    task :install_dependencies => :install_gems do
      missing = Sube::Gem::SPEC.dependencies.select { |dep| Gem::SourceIndex.from_installed_gems.search(dep).empty? }
      missing.delete_if { |dep| dep.respond_to?(:git_uri) && git_clone(dep) } if ENV['dev'] # Get source for missing gems
      unless missing.empty?
        puts "Missing dependencies: "
        missing.each { |dep| puts "- #{dep}" }
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

    desc "Download and setup files from external proyects"
    task :install_vendor => [:install_extjs, :install_jwplayer]
    
    
    task :install_requirements => [:install_vendor, :install_dependencies]

  end
end

task :setup => ['setup:install_requirements']

