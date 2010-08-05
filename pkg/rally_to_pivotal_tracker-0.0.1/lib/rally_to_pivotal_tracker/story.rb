class Story

  class << self
    attr_accessor :stories
    attr_accessor :tasks
    attr_accessor :iterations
    attr_accessor :pivotal_tracker_stories
    attr_accessor :user_map
    attr_accessor :export_path
  end

  private
  
  # supported pivotal fields
  def self.pivotal_tracker_fields
    @@pivotal_tracker_fields ||= ['Id', 'Story', 'Labels', 'Iteration', 'Iteration Start', 'Iteration End', 'Story Type', 'Estimate', 'Current State', 'Created at', 'Accepted at', 'Deadline', 'Requested By', 'Owned By', 'Description']
  end

  # Fields that we add but but keep blank
  def self.empty_pivotal_tracker_fields
    @@empty_pivotal_tracker_fields ||= ['Id']
  end

  # pivotal fields that have similar values
  def self.mapped_pivotal_tracker_fields
    @@mapped_pivotal_tracker_fields ||= { 'Accepted at' => 'Iteration End', 'Requested By' => 'Owned By', 'Deadline' => 'Iteration End' }    
  end

  # configuration
  def self.task_status
    @@task_status ||= Proc.new { |status| status == 'Completed' ? 'completed' : 'not completed' }    
  end

  def self.state_mapping
    @@state_mapping ||= Proc.new { |state|
      {
        'Backlog' => 'unscheduled',
        'Defined' => 'unstarted',
        'In-Progress' => 'started',
        'Completed' => 'delivered',
        'Accepted' => 'accepted'
      }[state] || ''
    }
  end

  def self.snap_to_estimate
    @@snap_to_estimate ||= Proc.new { |estimate|
      estimate = estimate.to_f
      if estimate > 8.0
        estimate = 8.0
      elsif estimate < 1.0
        estimate = 1.0
      elsif estimate < 2.0
        estimate = 2.0
      elsif estimate < 3.0
        estimate = 3.0
      elsif estimate < 5.0
        estimate = 5.0
      else
        estimate = 0        
      end
      estimate.to_i
    }
  end
  
  def self.user_mapping
    @@user_mapping ||= Proc.new { |person| 
      user = @@user_map.find { |u| u['rally_name'] == person }
       user && user['pivotal_name'] || ''
    }
  end

  def self.user_initials_mapping
    @@user_initials_mapping ||= Proc.new { |person| 
      user = @@user_map.find { |u| u['rally_name'] == person }
      user && user['pivotal_initials'] || ''
    }
  end

  def self.format_date
    @@format_date ||= Proc.new { |date|
      Date.parse(date).strftime('%d-%b-%y')
    }
  end
 
  # Labels should be comma seeparates
  def self.story_field_map
    @@story_field_map ||= {
      'Formatted ID' => 'Description', 
      'Name' => 'Story', 
      'Release' => 'Labels', 
      'Iteration' => ['Iteration', Proc.new { |iteration| iteration.to_s.gsub('Sprint ', '') }], 
      'Schedule State' => ['Current State', state_mapping], 
      'Plan Estimate' => ['Estimate', snap_to_estimate], 
      'Task Estimate Total' => nil, 
      'Task Remaining Total' => nil, 
      'Owner' => ['Owned By', user_mapping], 
      'Package' => 'Labels', 
      'Last Update Date' => nil, 
      'Notes' => 'Note', 
      'Object ID(OID)' => 'Description', 
      'Priority' => nil, 
      'Project' => nil, 
      'Tags' => nil, 
      'Actual' => nil, 
      'Blocked' => nil, 
      'Creation Date' => ['Created at', format_date], 
      'Description' => 'Description', 
      'Epic Group' => 'Labels'
    }             
  end

  def self.stories
    @@stories ||= []    
  end

  def self.tasks
    @@tasks ||= []    
  end

  def self.iterations
    @@iterations ||= []    
  end

  def self.pivotal_tracker_stories
    @@pivotal_tracker_stories ||= []    
  end
      
  public

  def self.user_config_path=(path)
    puts "user_config: #{path}" if ENV['verbose'] == 'true'
    raise ArgumentError, "user_config path not found" unless File.exist?(path)
    @@user_map = YAML.load_file(path) 
  end

  def self.export_path=(path)
    puts "export_path: #{path}" if ENV['verbose'] == 'true'
    raise ArgumentError, "export_path path not found" unless File.exist?(path)
    path = path.split('/').compact
    stories
    load_story_file(File.join(*path, 'stories.csv'))
    tasks
    load_task_file(File.join(*path, 'tasks.csv'))
    iterations
    load_iterations_file(File.join(*path, 'iterations.csv'))
    @@export_path = File.join(*path)
  end

  def self.export_path
    @@export_path    
  end
  
  def self.load_story_file(file)
    raise ArgumentError, "story file was not found, check path and try again: #{file}" unless File.exist?(file)
    
    CSV.foreach(file, :headers => true, :skip_blanks => true) do |row|
      add_story(row.to_hash)
    end

  end

  def self.add_story(story={})
    return false if find_story_by_rally_id(story['Formatted ID'])
    @@stories << story
  end
  
  def self.reset_stories
    @@stories = []
  end

  def self.find_story_by_rally_id(story_id)
    @@stories.find { |s| s['Formatted ID'] == story_id }
  end

  #
  # Tasks
  #
  
  def self.load_task_file(file)
    raise ArgumentError, "task file was not found, check path and try again: #{file}" unless File.exist?(file)

    CSV.foreach(file, :headers => true, :skip_blanks => true) do |row|
      add_task(row.to_hash)
    end

  end

  def self.add_task(task={})
    return false if find_task_by_id(task['Formatted ID'])
    # puts task.inspect if ENV['verbose'] == 'true'
    task['Formatted Story ID'] = task['Work Product'] && task['Work Product'].split(':').first
    @@tasks << task
  end

  def self.reset_tasks
    @@tasks = []
  end

  def self.find_task_by_id(task_id)
    @@tasks.find { |s| s['Formatted ID'] == task_id }
  end

  def self.find_tasks_by_rally_story_id(story_id)
    @@tasks.select { |s| s['Formatted Story ID'] == story_id }
  end

  def self.attach_tasks_to_stories
    @@stories.each_with_index do |story, index|
      @@stories[index][:tasks] = find_tasks_by_rally_story_id(story['Formatted ID'])
    end
  end

  #
  # Iterations
  #

  def self.load_iterations_file(file)
    raise ArgumentError, "iterations file was not found, check path and try again: #{file}" unless File.exist?(file)
    CSV.foreach(file, :headers => true, :skip_blanks => true) do |row|
      add_iteration(row.to_hash)
    end
  end

  def self.add_iteration(iteration={})
    return false if find_iteration_by_id(iteration['Name'])
    @@iterations << iteration
  end

  def self.reset_iterations
    @@iterations = []
  end

  def self.find_iteration_by_id(iteration_id)
    @@iterations.find { |s| s['Name'] == iteration_id }
  end

  def self.build_pivotal_tracker_stories
    raise RuntimeError, "unable to build stories that have not yet been loaded" unless @@stories && @@stories.size > 0
    raise RuntimeError, "unable to build tasks that have not yet been loaded" unless @@tasks && @@tasks.size > 0
    raise RuntimeError, "unable to build iterations that have not yet been loaded" unless @@iterations && @@iterations.size > 0
    attach_tasks_to_stories

    # TODO: clean this bad boy up and refactor out the configuration into files that can be easily managed

    @@pivotal_tracker_stories = []
    @@stories.each do |story|

      new_story = {}
      to_field = {}

      story_field_map.each do |field, value|

        to_field[field] ||= { :name => nil, :value => '', :proc => nil }
        case value.class.to_s
        when 'Array'
          to_field[field][:name] = value.first
          to_field[field][:value] << story[field].to_s
          to_field[field][:proc] = value.last
        when 'String'
          to_field[field][:name] = value
          if ['Labels', 'Description'].include?(value)
            to_field[field][:value] = [] if to_field[field][:value] == ''
            to_field[field][:value] << "#{field}: #{story[field]}" if story[field] and story[field] != ''
          else
            to_field[field][:value] = story[field] if story[field] and story[field] != ''
          end
        else
          puts "skipping #{field}/#{value}/#{value.class}" if ENV['verbose'] == 'true'
        end

      end

      # add iteration information
      iteration = find_iteration_by_id(to_field['Iteration'][:value])
      to_field['Start Date'] = { :name => 'Iteration Start', :value => iteration && format_date.call(iteration['Start Date']) || '' }
      to_field['End Date'] = { :name => 'Iteration End', :value => iteration && format_date.call(iteration['End Date']) || '' }

      # add required missing required fields
      to_field['Story Type'] = { :name => 'Story Type', :value => 'feature' }

      # create a list of cleaned storied, post process using procs, and assemble pointers
      tmp_story = {}
      pivotal_tracker_fields.each do |field|
        begin
          next if empty_pivotal_tracker_fields.include?(field)
          pointer_name = mapped_pivotal_tracker_fields[field]
          element = to_field.find { |e| (!pointer_name.nil? && e[1][:name] == pointer_name) || e[1][:name] == field }.last 
          if element[:proc]
            tmp_story[field] = element[:proc].call(element[:value])
          else
            tmp_story[field] = element[:value]
          end
        rescue => e
          puts e
        end
      end

      # collapse Labels and Description arrays
      tmp_story['Labels'] = tmp_story['Labels'].join(',')
      tmp_story['Description'] = tmp_story['Description'].join('\n')
    
      # preserve the Formatted ID for look up later
      tmp_story['Formatted ID'] = story['Formatted ID']
      
      @@pivotal_tracker_stories << tmp_story
    end
    write_out_pivotal_stories
  end

  private
  
  def self.write_out_pivotal_stories
    
    # append tasks to rows
    rows = []
    max_task_count = 0
    @@pivotal_tracker_stories.each do |story|
      row = []
      pivotal_tracker_fields.each do |field|
        row << story[field]
      end

      # add tasks for the story
      if tmp_tasks = find_tasks_by_rally_story_id(story['Formatted ID'])
        max_task_count = tmp_tasks.size if tmp_tasks.size > max_task_count
        tmp_tasks.each do |task|
          initials = user_initials_mapping.call(task['Owner'])
          raise "Missing user information, please update user mapping configuration." unless initials
          row << ["#{initials}: #{task['Name']}", task_status.call(task['Scheduled State'])]
        end
      end
      rows << row.flatten
    end

    rows = rows.sort { |a,b| a[4] <=> b[4] }

    # write out stories, ensureing that we add enough task headers
    puts "Writing to: #{export_path}/pivotal_stories.csv" if ENV['verbose'] == 'true'
    CSV.open("#{export_path}/pivotal_stories.csv", "w") do |csv|
      max_task_count.times do
        pivotal_tracker_fields << ['Task','Task Status']
      end

      csv << pivotal_tracker_fields.flatten # header
      count = 0
      rows.each do |row|
        csv << row
        count += 1
        puts "wrote #{count} stories" if count % 25 == 0        
      end
      puts "completed #{count} stories"      
    end

  end

end