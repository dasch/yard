require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Server do
  before do
    @projects = {}
    @options = {:single_project => true, :caching => false}
    @server_options = {:Port => 8808}
    @adapter = mock(:adapter)
    @cli = YARD::CLI::Server.new
    @cli.stub!(:adapter).and_return(@adapter)
  end
  
  def run(*args)
    @projects = {File.basename(Dir.pwd) => '.yardoc'} if @projects.empty?
    @projects.values.each {|dir| File.should_receive(:exist?).with(dir).and_return(true) }
    @adapter.should_receive(:new).with(@projects, @options, @server_options).and_return(@adapter)
    @adapter.should_receive(:start)
    @cli.run(*args.flatten)
  end

  it "should default to current dir if no project is specified" do
    Dir.should_receive(:pwd).and_return('/path/to/foo')
    @projects['foo'] = '.yardoc'
    run
  end
  
  it "should use .yardoc as yardoc file is project list is odd" do
    @projects['a'] = '.yardoc'
    run 'a'
  end
  
  it "should force multi project if more than one project is listed" do
    @options[:single_project] = false
    @projects['a'] = 'b'
    @projects['c'] = '.yardoc'
    run %w(a b c)
  end
  
  it "should accept -m, --multi-project" do
    @options[:single_project] = false
    run '-m'
    run '--multi-project'
  end
  
  it "should accept -c, --cache" do
    @options[:caching] = true
    run '-c'
    run '--cache'
  end
  
  it "should accept -r, --reload" do
    @options[:incremental] = true
    run '-r'
    run '--reload'
  end
  
  it "should accept -d, --daemon" do
    @server_options[:daemonize] = true
    run '-d'
    run '--daemon'
  end
  
  it "should accept -p, --port" do
    @server_options[:Port] = 10
    run '-p', '10'
    run '--port', '10'
  end
  
  it "should accept --docroot" do
    @server_options[:DocumentRoot] = '/foo/bar'
    run '--docroot', '/foo/bar'
  end
  
  it "should accept -a webrick to create WEBrick adapter" do
    @cli.should_receive(:adapter=).with(YARD::Server::WebrickAdapter)
    run '-a', 'webrick'
  end
  
  it "should accept -a rack to create Rack adapter" do
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    run '-a', 'rack'
  end
  
  it "should default to Rack adapter if exists on system" do
    @cli.unstub(:adapter)
    @cli.should_receive(:require).with('rubygems').and_return(false)
    @cli.should_receive(:require).with('rack').and_return(true)
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    @cli.send(:select_adapter)
  end

  it "should fall back to WEBrick adapter if Rack is not on system" do
    @cli.unstub(:adapter)
    @cli.should_receive(:require).with('rubygems').and_return(false)
    @cli.should_receive(:require).with('rack').and_raise(LoadError)
    @cli.should_receive(:adapter=).with(YARD::Server::WebrickAdapter)
    @cli.send(:select_adapter)
  end
  
  it "should accept -s, --server" do
    @server_options[:server] = 'thin'
    run '-s', 'thin'
    run '--server', 'thin'
  end
end