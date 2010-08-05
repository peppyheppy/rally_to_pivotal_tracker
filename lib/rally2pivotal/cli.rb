require 'optparse'
require 'rally_to_pivotal_tracker'
require 'rally_to_pivotal_tracker/story'
module Rally2pivotal
  class CLI
    def self.execute(stdout, arguments=[])

      options = {
        :user_config_path     => "#{`pwd`.chomp}/user_config.yml",
        :export_path          => "#{`pwd`.chomp}"
      }
      mandatory_options = %w(  )

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Move your stories, tasks, and iterations from Rally to Pivotal Tracker

          Usage: #{File.basename($0)} [options]

          Options are:
        BANNER
        opts.separator ""
        opts.on("-u", "--user_config_path PATH", String,
                "The path to the YAML user configuration mapping file.",
                "This file should contain mappings from your Rally users to your Pivotal Tracker users.",
                "Example format:\n\n---\n-\n  rally_name: heppy\n  pivotal_name: Peppy Heppy\n  pivotal_initials: PH\n-\n  rally_name: heppy\n  pivotal_name: Peppy Heppy\n  pivotal_initials: PH\n",
                "Default: #{`pwd`.chomp}/user_config.yml") { |arg| options[:user_config_path] = arg }
        opts.on("-e", "--export_path PATH", String,
                "The path to the exported stories, tasks, and iterations from Rally.",
                "Assumes that these three files are in the same directory: stories.csv, tasks.csv, iterations.csv.",
                "Default: #{`pwd`.chomp}") { |arg| options[:export_path] = arg }
        opts.on("-v", "--verbose", "Run verbosely") do |v|
                 options[:verbose] = 'true' if v
        end
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.parse!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      puts "...... #{options[:verbose]}"

      stdout.puts "Starting"
      ENV['verbose'] = 'true' if options[:verbose] == 'true'
      stdout.puts "Loading user configuration..."
      Story.user_config_path = options[:user_config_path]
      stdout.puts " done."
      stdout.puts "Loading stories, tasks, and iterations..."
      Story.export_path = options[:export_path]
      stdout.puts " done."
      stdout.puts "Exporting to Pivotal Tracker csv..."
      Story.build_pivotal_tracker_stories
      stdout.puts " done."      
    end
  end
end