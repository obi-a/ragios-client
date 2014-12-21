require 'rubygems'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios-client'))

#use for fast tests
plugin = "mock_plugin"

def generate_json(str)
  JSON.generate(str)
end

admin = 'admin'
password = 'ragios'

describe "Ragios Client" do
  before(:each) do
    #@ragios = Ragios::Client.new(username: admin, password: password)
    @ragios = Ragios::Client.new
  end
  describe "queries" do
    before(:each) do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: ["gmail_notifier","twitter_notifier"],
        plugin: plugin
      }
      @query_monitor_id = @ragios.create(monitor)[:_id]
    end
    describe "#events" do
      it "returns all events by monitor" do
        @ragios.events(@query_monitor_id, "1980","2015").should_not == 0
        first_id = @ragios.events(@query_monitor_id, "1980","2015").first[:monitor][:_id]
        @query_monitor_id.should == first_id
        @ragios.events(@query_monitor_id, "1980","2015", 1).count.should == 1
      end
    end
    describe "#events_by_state" do
      it "returns a monitor's events by specified state" do
        @ragios.events_by_state(@query_monitor_id, "started", "1980","2015",1).count.should == 1
      end
    end
    after(:each) do
      @ragios.delete(@query_monitor_id)
    end
  end
  describe "#create" do
    it "creates a monitor" do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: ["gmail_notifier","twitter_notifier"],
        plugin: plugin
      }

      returned_monitor = @ragios.create(monitor)
      returned_monitor.should include(monitor)
      monitor_id = returned_monitor[:_id]

      #teardown
      @ragios.delete(monitor_id)
    end

    it "cannot create a monitor with no plugin" do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: "gmail_notifier"
      }
      begin
        @ragios.create monitor
      rescue => e
        e.should be_an_instance_of Ragios::ClientException
        e.message.should include("No Plugin Found")
      end
    end

    it "cannot create a monitor with no notifier" do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        plugin: plugin
      }
      begin
        @ragios.create monitor
      rescue Exception => e
        e.should be_an_instance_of Ragios::ClientException
        e.message.should include("No Notifier Found")
      end
    end

    it "cannot create a badly formed monitor" do
      expect{@ragios.create("bad data")}.to raise_error(JSON::GeneratorError)
    end
  end
  describe "More API calls" do
    before(:each) do
      @unique_name = "Google #{Time.now.to_i}"
      @monitor = {
        monitor: @unique_name,
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: ["gmail_notifier"],
        plugin: plugin,
        tag: "test"
      }

      returned_monitor = @ragios.create(@monitor)
      @monitor_id = returned_monitor[:_id]
    end
    describe "#find" do
      it "should retrieve a monitor by id" do
        received_monitor = @ragios.find(@monitor_id)
        received_monitor.should include(@monitor)
      end
      it "cannot retrieve a monitor that doesnt exist" do
        expect{ @ragios.find('dont_exist') }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = dont_exist"))
      end
    end
    describe "#where" do
      it "should find monitors that match multiple key/value pairs" do
        options = {tag: 'test', every: '5m', monitor: @unique_name}
        found_monitors = @ragios.where(options)
        found_monitors.first.should include(@monitor)
      end
      it "returns an empty array when no monitor matches multiple key/value pairs" do
        options = {something: "dont_exist", every: "5m", monitor: "dont_exist"}
        @ragios.where(options).should == []
      end
    end
    describe "#update" do
      it "should update a monitor" do
        update_options = {every: "10m", via: ["twitter_notifier"]}
        @ragios.update(@monitor_id, update_options).should == {ok: true}
      end
      it "cannot update a monitor with bad data" do
        expect { @ragios.update(@monitor_id,"bad data") }.to raise_error(JSON::GeneratorError)
      end
      it "cannot update a monitor that don't exist" do
        update_options = {every: "5m", via: ["twitter_notifier"]}
        expect { @ragios.update("dont_exist", update_options) }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = dont_exist"))
      end
    end
    describe "#test" do
      it "tests a monitor" do
        @ragios.test(@monitor_id).should == {ok: true}
      end
      it "cannot test a monitor that don't exist" do
        expect { @ragios.test("dont_exist") }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = dont_exist"))
      end
    end
    describe "#delete" do
      it "deletes a monitor" do
        new_monitor_id = @ragios.create(@monitor)[:_id]
        @ragios.delete(new_monitor_id).should == {ok: true}
      end
      it "cannot delete a monitor that doesnt exist" do
        this_monitor_id = "dont_exist"
        expect{ @ragios.find(this_monitor_id) }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = #{this_monitor_id}"))
      end
    end
    describe "#stop" do
      it "stops an active monitor" do
        active_monitor = @ragios.find(@monitor_id)
        active_monitor[:status_].should == "active"

        @ragios.stop(@monitor_id).should == {ok: true}

        stopped_monitor = @ragios.find(@monitor_id)
        stopped_monitor[:status_].should == "stopped"

        #stop monitor is idempotent
        @ragios.stop(@monitor_id).should == {ok: true}
      end
      it "cannot stop a monitor that dont exist" do
        this_monitor_id = "dont_exist"
        expect { @ragios.stop(this_monitor_id) }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = #{this_monitor_id}"))
      end
    end
    describe "#start" do
      it "starts a stopped monitor" do
        @ragios.stop(@monitor_id)
        stopped_monitor = @ragios.find(@monitor_id)
        stopped_monitor[:status_].should == "stopped"

        @ragios.start(@monitor_id).should == {ok: true}

        active_monitor = @ragios.find(@monitor_id)
        active_monitor[:status_].should == "active"

        #start monitor is idempotent
        @ragios.start(@monitor_id).should == {ok: true}
      end
      it "cannot start a monitor that dont exist" do
        this_monitor_id = "dont_exist"
        expect { @ragios.start(this_monitor_id) }.to raise_error(Ragios::ClientException, generate_json(error: "No monitor found with id = #{this_monitor_id}"))
      end
    end
    describe "#all" do
      it "retrieves all monitors" do
        retrieved_monitors = @ragios.all
        retrieved_monitors.should_not be_empty
        retrieved_monitors.should be_an_instance_of Array
      end
      it "can limit the number of monitors retrieved" do
        @ragios.all(limit = 1).count.should == 1
      end
    end
    after(:each) do
      @ragios.delete(@monitor_id)
    end
  end

  it "accepts correct login credentials" do
    expect{ @ragios.login(admin, password) }.to_not raise_error
  end

  it "rejects incorrect login credentials" do
    expect { @ragios.login('incorret','incorret') }.to raise_error(Ragios::ClientException, generate_json(error: "You are not authorized to access this resource"))
  end

  it "has default settings" do
    ragios_client = Ragios::Client.new
    ragios_client.address.should == "http://127.0.0.1"
    ragios_client.port.should == "5041"
    ragios_client.username.should == nil
    ragios_client.password.should == nil
  end

  it "accepts new default address" do
    ragios_client = Ragios::Client.new(address: 'https://mysite.com', port: '6802')
    ragios_client.address.should == "https://mysite.com"
    ragios_client.port.should == "6802"
    ragios_client.username.should == nil
    ragios_client.password.should == nil
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
