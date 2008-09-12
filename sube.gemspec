# -*- ruby -*- 

require 'rubygems'

module Sube
  module Gem

    module Specification
      def add_dependency(gem, *requirements)
        opts = requirements.last.kind_of?(Hash) ? requirements.pop : {}
        m = Module.new { opts.keys.each { |k| attr_accessor k } }
        dep = super(gem, *requirements)
        gem = dep.last.extend m
        opts.each_pair { |name, value| gem.send("#{name}=", value) }
        dep
      end
    end

  end
end

Gem::Specification.new do |spec|
  spec.extend Sube::Gem::Specification

  spec.name = 'sube'
  spec.version = '0.0.1'
  spec.author = 'Victor Hugo Borja'
  spec.email = 'vic.borja@gmail.com'
  spec.homepage = 'http://github.com/vic/sube'
  spec.summary = 'A web-based subtitle editor'

  # spec.rubyforge_project = 'sube'
  
  spec.files = Dir['lib/**/*', 'bin/**/*', 'public/**/*', 'views/**/*', 'Rakefile']

  spec.require_paths = ['lib']
  spec.bindir = 'bin'
  spec.executable = 'sube'
  
  spec.has_rdoc = true
  spec.extra_rdoc_files = ['README.rdoc', 'CHANGELOG', 'LICENSE', 'NOTICE', 'DISCLAIMER']

  spec.rdoc_options     << '--title' << "SubE" << '--main' << 'README.rdoc' <<
                           '--line-numbers' << '--inline-source' << '-p' <<
                           '--webcvs' << 'http://github/vic/sube/tree/master/'

  spec.add_dependency 'sinatra', :git_uri => 'git://github.com/bmizerany/sinatra.git'
  spec.add_dependency 'mongrel'
  spec.add_dependency 'json'
  spec.add_dependency 'builder'
  spec.add_dependency 'haml'
  spec.add_dependency 'RedCloth'
  spec.add_dependency 'hpricot'
  spec.add_dependency 'mechanize'
  spec.add_dependency 'akitaonrails-mygist', :gem_repo => 'http://gems.github.com',
                                             :git_uri => 'git://github.com/akitaonrails/mygist.git'

  spec.add_dependency 'nofxx-subtitle_it', :gem_repo => 'http://gems.github.com',
                                           :git_uri => 'git://github.com/nofxx/subtitle_it.git'
  
  Sube::Gem::SPEC = spec
end

