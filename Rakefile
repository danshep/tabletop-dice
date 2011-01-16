require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec') do |task|
  task.rspec_opts = '-f d --fail-fast'
end

namespace :spec do
  task :continuous do
    files = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']
    last_max = nil
    begin
      max = files.map {|f| File.mtime(f) rescue nil }.compact.max
      if max != last_max
        begin
          Rake::Task['spec'].execute  
        rescue RuntimeError => e
          p e
        end
        last_max = max
      end
    end while sleep 1
  end
end
