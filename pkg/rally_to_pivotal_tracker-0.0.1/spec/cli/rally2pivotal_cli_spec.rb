require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rally2pivotal/cli'

describe Rally2pivotal::CLI, "execute" do
  before(:each) do
    @stdout_io = StringIO.new
    Rally2pivotal::CLI.execute(@stdout_io, [])
    @stdout_io.rewind
    @stdout = @stdout_io.read
  end
  
  # it "should print default output" do
  #   @stdout.should =~ /user_config path not found/
  # end
end