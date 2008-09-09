require 'rake/gempackagetask'

package = Rake::GemPackageTask.new(Sube::Gem::SPEC) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

task :package => 'setup:install_vendor'

