require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'ruby-debug'
require 'rally_to_pivotal_tracker/story.rb'

describe Story do

  before :each do
    Story.user_config_path = File.expand_path(File.dirname(__FILE__) + '/../../fixtures/config/user_config.yml')      
  end

  describe "loading stories from Rally" do

    before :each do 
      Story.reset_stories
      Story.user_config_path = File.expand_path(File.dirname(__FILE__) + '/../../fixtures/config/user_config.yml')      
    end

    it "should raise error if file does not exist" do
      lambda {
        Story.load_story_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/stories_missing.should_not_exist'))
      }.should raise_error(ArgumentError)
    end

    it "should have a load from file method" do
      Story.should respond_to :load_story_file
    end

    it "should have stories method" do
      Story.stories.should be_a Array
      Story.stories.size.should == 0      
    end

    it "should have a load from file method" do
      Story.should respond_to :add_story
    end

    it "should add story from hash to stories list" do
      Story.stories.size.should == 0
      Story.add_story({ 'booga' => 'wooga', 'Formatted ID' => 'US100' })
      Story.stories.size.should == 1
    end

    it "should be able to find a story in the stack" do
      Story.stories.size.should == 0
      Story.add_story({ 'booga' => 'wooga', 'Formatted ID' => 'US100' })
      Story.find_story_by_rally_id('US100').should_not be_nil
    end

    it "should ensure unique stories when adding a new story" do
      Story.stories.size.should == 0
      2.times do 
        Story.add_story({ 'booga' => 'wooga', 'Formatted ID' => 'US100' })
      end
      Story.stories.size.should == 1 # should stay one because we added the same story twice
    end

    it "should load stories into memory" do
      Story.reset_stories
      Story.load_story_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/stories.csv'))
      Story.stories.size.should_not == 0
    end

  end

  describe "loading tasks from Rally" do

    before :each do 
      Story.reset_tasks
    end

    it "should raise error if file does not exist" do
      lambda {
        Story.load_task_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/tasks_missing.should_not_exist'))
      }.should raise_error(ArgumentError)
    end

    it "should have a load from file method" do
      Story.should respond_to :load_task_file
    end

    it "should have tasks method" do
      Story.tasks.should be_a Array
      Story.tasks.size.should == 0      
    end

    it "should have a load from file method" do
      Story.should respond_to :add_task
    end

    it "should add task from hash to tasks list" do
      Story.tasks.size.should == 0
      Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA100','Work Product' => 'US100: The Stuff' })
      Story.tasks.size.should == 1
    end

    it "should be able to find a task in the stack" do
      Story.tasks.size.should == 0
      Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA100', 'Work Product' => 'US100: The Stuff' })
      Story.find_tasks_by_rally_story_id('US100').should_not be_nil
    end

    it "should ensure unique tasks when adding a new task" do
      Story.tasks.size.should == 0
      2.times do 
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA100','Work Product' => 'US100: The Stuff' })
      end
      Story.tasks.size.should == 1 # should stay one because we added the same task twice
    end

    describe "loading and finding tasks" do

      before :each do
        Story.reset_stories
        Story.reset_tasks
        Story.reset_iterations
        Story.load_task_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/iterations.csv'))
      end
      
    end

    describe "loading and finding tasks" do

      before :each do
        Story.reset_stories
        Story.reset_tasks
        Story.reset_iterations
        Story.user_config_path = File.expand_path(File.dirname(__FILE__) + '/../../fixtures/config/user_config.yml')
        Story.load_story_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/stories.csv'))
        Story.load_task_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/tasks.csv'))
        Story.load_iterations_file(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/rally/iterations.csv'))        
      end
      
      it "should load tasks into memory" do
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999999','Work Product' => 'US999999: The Stuff' })
        Story.tasks.size.should_not == 0
      end

      it "should find task by task id" do
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999999','Work Product' => 'US999999: The Stuff' })
        Story.find_task_by_id('TA999999')
      end

      it "should find tasks by formatted story id" do
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999999','Work Product' => 'US999999: The Stuff' })
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999998','Work Product' => 'US999999: The Stuff' })
        Story.find_tasks_by_rally_story_id('US999999').should_not be_nil
      end

      it "should attach tasks to story" do
        Story.add_story({ 'booga' => 'wooga', 'Formatted ID' => 'US999999' })
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999999','Work Product' => 'US999999: The Stuff' })
        Story.add_task({ 'booga' => 'wooga', 'Formatted ID' => 'TA999998','Work Product' => 'US999999: The Stuff' })        
        Story.attach_tasks_to_stories
        Story.find_story_by_rally_id('US999999')[:tasks].should be_a Array
      end

      it "should export to pivotal tracker format" do
        Story.pivotal_tracker_stories.should be_a Array
        Story.build_pivotal_tracker_stories
        Story.pivotal_tracker_stories.should_not be_empty
      end

    end
    
  end

  describe "Iterations" do

    it "should load iterations into memory" do
      Story.iterations
      Story.add_iteration({ 'booga' => 'wooga', 'Name' => 'Sprint 1'})
      Story.iterations.size.should_not == 0
    end

    it "should find iteration by iteration id" do
      Story.iterations
      Story.add_iteration({ 'booga' => 'wooga', 'Name' => 'Sprint 1'})
      Story.find_iteration_by_id('TA999999')
    end

  end
  
end
