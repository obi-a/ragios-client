require 'rubygems'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios-client'))

#use for fast testing
plugin = "mock_plugin"
#using the url_monitor plugin will perform a real http request on each check leading to slow tests
#plugin = "url_monitor"

admin = 'admin'
password = 'ragios'

describe "Ragios Client" do
  before(:each) do
    @ragios = Ragios::Client.new(username: admin,password: password)
  end

  it "adds a monitor" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier","twitter_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    returned_monitors.first.should include(monitors.first)
    monitor_id = returned_monitors.first[:_id]

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot add a monitor with no plugin" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier"}]
    begin
      @ragios.add monitors
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No Plugin Found")
    end
  end

  it "cannot add a monitor with no notifier" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      plugin: plugin }]
    begin
      @ragios.add monitors
    rescue Exception => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No Notifier Found")
    end
  end

  it "cannot add a badly formed monitor" do
    expect{@ragios.add("bad data")}.to raise_error(Ragios::ClientException)
  end

  it "should retrieve a monitor by id" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    received_monitor = @ragios.find(monitor_id)
    received_monitor.should include(monitors.first)
    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot retrieve a monitor that doesnt exist" do
    begin
      @ragios.find('dont_exist')
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = dont_exist")
    end
  end

  it "should find monitors that match multiple key/value pairs" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin,
      tag: "test" }]
    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    options = {tag: 'test', every: '5m', monitor: unique_name}
    found_monitors = @ragios.find_by(options)
    found_monitors.first.should include(monitors.first)

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "returns an empty array when no monitor matches multiple key/value pairs" do
    options = {something: "dont_exist", every: "5m", monitor: "dont_exist"}
    @ragios.find_by(options).should == []
  end

  it "should update a monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    update_options = {every: "10m", via: ["twitter_notifier"]}
    updated_monitor = @ragios.update(monitor_id, update_options)
    updated_monitor.should include(update_options)

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot update a monitor with bad data" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    expect { @ragios.update(monitor_id,"bad data") }.to raise_error(Ragios::ClientException)

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot update a monitor that don't exist" do
    update_options = {every: "5m", via: ["twitter_notifier"]}
    monitor_id = "dont_exist"
    begin
      @ragios.update(monitor_id,update_options)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = dont_exist")
    end
  end

  it "tests a monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    hash = @ragios.test(monitor_id)
    hash[:ok].should == true

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot test a monitor that don't exist" do
    monitor_id = "dont_exist"
    begin
      @ragios.test(monitor_id)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = dont_exist")
    end
  end

  it "deletes a monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
    begin
      @ragios.find(monitor_id)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = #{monitor_id}")
    end
  end

  it "cannot delete a monitor that doesnt exist" do
    monitor_id = "dont_exist"
    begin
      @ragios.find(monitor_id)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = #{monitor_id}")
    end
  end

  it "stops an active monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    active_monitor = @ragios.find(monitor_id)
    active_monitor[:status_].should == "active"

    hash = @ragios.stop(monitor_id)
    hash[:ok].should == true

    stopped_monitor = @ragios.find(monitor_id)
    stopped_monitor[:status_].should == "stopped"

    #stop monitor is idempotent
    hash = @ragios.stop(monitor_id)
    hash[:ok].should == true

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot stop a monitor that dont exist" do
    monitor_id = "dont_exist"
    begin
      @ragios.stop(monitor_id)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = #{monitor_id}")
    end
  end

  it "restarts a stopped monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    @ragios.stop(monitor_id)
    stopped_monitor = @ragios.find(monitor_id)
    stopped_monitor[:status_].should == "stopped"

    hash = @ragios.restart(monitor_id)
    hash[:ok].should == true

    active_monitor = @ragios.find(monitor_id)
    active_monitor[:status_].should == "active"

    #restart monitor is idempotent
    hash = @ragios.restart(monitor_id)
    hash[:ok].should == true

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "cannot restart a monitor that dont exist" do
    monitor_id = "dont_exist"
    begin
      @ragios.restart(monitor_id)
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("No monitor found with id = #{monitor_id}")
    end
  end

  it "accepts correct login credentials" do
    expect{ @ragios.login(admin, password) }.to_not raise_error
  end

  it "rejects incorrect login credentials" do
    begin
      @ragios.login('incorret','incorret')
    rescue => e
      e.should be_an_instance_of Ragios::ClientException
      e.message.should include("You are not authorized to access this resource")
    end
  end

  it "retrieves all monitors" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: plugin }]

    returned_monitors = @ragios.add monitors
    monitor_id = returned_monitors.first[:_id]
    #setup ends

    retrieved_monitors = @ragios.all
    retrieved_monitors.should_not be_empty
    retrieved_monitors.should be_an_instance_of Array

    #teardown
    hash = @ragios.delete(monitor_id)
    hash[:ok].should == true
  end

  it "has default settings" do
    ragios_client = Ragios::Client.new
    ragios_client.address.should == "http://127.0.0.1"
    ragios_client.port.should == "5041"
    ragios_client.username.should == ""
    ragios_client.password.should == ""
  end

  it "accepts new default address" do
    ragios_client = Ragios::Client.new(address: 'https://mysite.com', port: '6802')
    ragios_client.address.should == "https://mysite.com"
    ragios_client.port.should == "6802"
    ragios_client.username.should == ""
    ragios_client.password.should == ""
  end

  it "accepts new default login credentials" do
    ragios_client = Ragios::Client.new(username: 'superadmin', password: 'abc123')
    ragios_client.address.should == "http://127.0.0.1"
    ragios_client.port.should == "5041"
    ragios_client.username.should == "superadmin"
    ragios_client.password.should == "abc123"
  end

    it "accepts new default settings" do
    ragios_client = Ragios::Client.new(username: 'superadmin', password: 'abc123', address: 'https://mysite.com', port: '6802')
    ragios_client.address.should == "https://mysite.com"
    ragios_client.port.should == "6802"
    ragios_client.username.should == "superadmin"
    ragios_client.password.should == "abc123"
  end

end
