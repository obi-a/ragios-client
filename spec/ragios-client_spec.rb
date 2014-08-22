require 'rubygems'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios-client'))

#use for fast tests
plugin = "mock_plugin"

admin = 'admin'
password = 'ragios'

describe "Ragios Client" do
  before(:each) do
    @ragios = Ragios::Client.new(username: admin,password: password)
  end
  describe "#add" do
    it "adds a monitor" do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: ["gmail_notifier","twitter_notifier"],
        plugin: plugin
      }

      returned_monitor = @ragios.add(monitor)
      returned_monitor.should include(monitors)
      monitor_id = returned_monitor[:_id]

      #teardown
      @ragios.delete(monitor_id)
    end

    it "cannot add a monitor with no plugin" do
      monitors = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: "gmail_notifier"
      }
      begin
        @ragios.add monitor
      rescue => e
        e.should be_an_instance_of Ragios::ClientException
        e.message.should include("No Plugin Found")
      end
    end

    it "cannot add a monitor with no notifier" do
      monitor = {
        monitor: "Google",
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        plugin: plugin
      }
      begin
        @ragios.add monitor
      rescue Exception => e
        e.should be_an_instance_of Ragios::ClientException
        e.message.should include("No Notifier Found")
      end
    end

    it "cannot add a badly formed monitor" do
      expect{@ragios.add("bad data")}.to raise_error(JSON::GeneratorError)
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

      returned_monitor = @ragios.add(monitor)
      @monitor_id = returned_monitor[:_id]
    end
    describe "#find" do
      it "should retrieve a monitor by id" do
        received_monitor = @ragios.find(@monitor_id)
        received_monitor.should include(@monitor)
      end
      it "cannot retrieve a monitor that doesnt exist" do
        expect{ @ragios.find('dont_exist') }.to raise_error(Ragios::ClientException, "No monitor found with id = dont_exist")
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
        updated_monitor = @ragios.update(@monitor_id, update_options)
        updated_monitor.should include(update_options)
      end
      it "cannot update a monitor with bad data" do
        expect { @ragios.update(@monitor_id,"bad data") }.to raise_error(JSON::GeneratorError)
      end
      it "cannot update a monitor that don't exist" do
        update_options = {every: "5m", via: ["twitter_notifier"]}
        expect { @ragios.update("dont_exist", update_options) }.to raise_error(Ragios::ClientException, "No monitor found with id = dont_exist")
      end
    end
    describe "#test" do
      it "tests a monitor" do
        @ragios.test(@monitor_id).should == {ok: true}
        hash[:ok].should == true
      end
      it "cannot test a monitor that don't exist" do
        expect { @ragios.test("dont_exist") }.to raise_error(Ragios::ClientException, "No monitor found with id = dont_exist")
      end
    end
    describe "#delete" do
      it "deletes a monitor" do
        @ragios.delete(@monitor_id).should == {ok: true}
      end
      it "cannot delete a monitor that doesnt exist" do
        this_monitor_id = "dont_exist"
        expect{ @ragios.find(this_monitor_id) }.to raise_error(Ragios::ClientException, "No monitor found with id = #{this_monitor_id}")
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
        monitor_id = "dont_exist"
        expect { @ragios.stop(monitor_id) }.to raise_error(Ragios::ClientException, "No monitor found with id = #{monitor_id}")
      end
    end
    describe "#restart" do
      it "restarts a stopped monitor" do
        @ragios.stop(@monitor_id)
        stopped_monitor = @ragios.find(@monitor_id)
        stopped_monitor[:status_].should == "stopped"

        @ragios.restart(@monitor_id).should == {ok: true}

        active_monitor = @ragios.find(@monitor_id)
        active_monitor[:status_].should == "active"

        #restart monitor is idempotent
        @ragios.restart(@monitor_id).should == {ok: true}
      end
      it "cannot restart a monitor that dont exist" do
        monitor_id = "dont_exist"
        expect { @ragios.restart(monitor_id) }.to raise_error(Ragios::ClientException, "No monitor found with id = #{monitor_id}")
      end
    end
    describe "#all" do
      it "retrieves all monitors" do
        retrieved_monitors = @ragios.all
        retrieved_monitors.should_not be_empty
        retrieved_monitors.should be_an_instance_of Array
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
    expect { @ragios.login('incorret','incorret') }.to raise_error(Ragios::ClientException, "You are not authorized to access this resource")
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
