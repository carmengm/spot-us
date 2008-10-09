# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

def timestamp(label)
 puts "*** #{label} @ #{DateTime.now.to_formatted_s :db} ***"
end

task :show_success do
 timestamp "SUCCESSFUL BUILD"
end

task :show_start => :environment do
 timestamp "BUILD"
end

desc "Copy application sample config for dev/test purposes"
task :copy_sample_config do
  if Rails.env.development? or Rails.env.test?
    settings_file         = File.join(Rails.root, *%w(config settings.yml))
    settings_file_example = File.join(Rails.root, *%w(config settings.example.yml))

    unless File.exist?(settings_file)
      puts "Setting up config/setting.yml from config/settings.example.yml..."
      FileUtils.cp(settings_file_example, settings_file)
    end
  end
end

task :environment => :copy_sample_config

Rake::Task[:default].clear() # clear out the default Rails test::unit tasks...

desc "Default task is to run the specs"
task :default => :spec
