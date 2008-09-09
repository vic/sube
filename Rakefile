module Sube
  load File.expand_path('sube.gemspec', File.dirname(__FILE__))
end

module Sube::Rake
  extend self

  def path_to(*args)
    File.expand_path(File.join(*args), File.dirname(__FILE__))
  end
  alias_method :_, :path_to

  task :run do
    sh 'ruby bin/sube'
  end
  
end
