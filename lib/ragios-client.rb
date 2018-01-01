require 'rest_client'
require 'multi_json'
require 'uri'

module Ragios

  class ClientException < StandardError; end

  class Client
    attr_reader :address
    attr_reader :port
    attr_reader :username
    attr_reader :password

    def initialize(args = {})
      @address = args.fetch(:address, 'http://127.0.0.1')
      @port = args.fetch(:port, '5041')
      @username = args.fetch(:username, nil)
      @password = args.fetch(:password, nil)
    end

    def login(username,password)
      @username = username
      @password = password
      auth_session
    end

    def create(monitor)
      api_request { RestClient.post "#{address_port}/monitors/", generate_json(monitor), http_request_options }
    end
    def find(monitor_id)
      api_request { RestClient.get "#{address_port}/monitors/#{monitor_id}/", auth_cookie }
    end
    def all(limit = nil)
      params = limit ? "?limit=#{limit}" : ""
      api_request { RestClient.get "#{address_port}/monitors#{params}", auth_cookie }
    end
    def stop(monitor_id)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "stopped"}, http_request_options }
    end
    def start(monitor_id)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "active"},http_request_options }
    end
    def delete(monitor_id)
      api_request { RestClient.delete "#{address_port}/monitors/#{monitor_id}", auth_cookie }
    end
    def where(options)
      api_request { RestClient.get "#{address_port}/monitors/attributes?#{URI.encode_www_form(options)}", auth_cookie }
    end
    def update(monitor_id, options)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",generate_json(options), http_request_options }
    end
    def find_event(event_id)
      api_request { RestClient.get "#{address_port}/events/#{event_id}/", auth_cookie }
    end
    def all_events(limit = nil)
      params = limit ? "?limit=#{limit}" : ""
      api_request { RestClient.get "#{address_port}/events#{params}", auth_cookie }
    end
    def delete_event(event_id)
      api_request { RestClient.delete "#{address_port}/events/#{event_id}", auth_cookie }
    end
    def events(monitor_id, startdate, enddate, limit=nil)
      api_request { RestClient.get "#{address_port}/monitors/#{monitor_id}/events", options(startdate, enddate, limit) }
    end
    def events_by_type(monitor_id, type, startdate, enddate, limit=nil)
      api_request { RestClient.get "#{address_port}/monitors/#{monitor_id}/events_by_type/#{type}", options(startdate, enddate, limit) }
    end
    def events_by_state(monitor_id, state, startdate, enddate, limit=nil)
      api_request { RestClient.get "#{address_port}/monitors/#{monitor_id}/events_by_state/#{state}", options(startdate, enddate, limit) }
    end
    def test(monitor_id)
      api_request { RestClient.post "#{address_port}/tests", {:id => monitor_id}, http_request_options }
    end

    def maestro_test(url, source_code)
      api_request { RestClient.post "#{address_port}/maestro/test", {url: url, source_code: source_code}, http_request_options }
    end

private
    def options(startdate, enddate, limit = nil)
      params = {}
      params[:start_date] = startdate
      params[:end_date] = enddate
      params[:limit] = limit if limit
      query_options = auth_cookie
      query_options[:params] = params
      query_options
    end
    def api_request
      response = yield
      parse_json(response)
    rescue => e
      raise_error(e)
    end

    def raise_error(e)
      e.respond_to?('response') ? raise(ClientException, e.response) : raise(e)
    end

    def auth_cookie
      {:cookies => {:RagiosAuthSession => auth_session}}
    end

    def http_request_options
      {:content_type => :json,
       :cookies => {:RagiosAuthSession => auth_session}
      }
    end

    def address_port
      "#{@address}:#{@port}"
    end

    def generate_json(str)
      MultiJson.dump(str)
    end

    def parse_json(str)
      MultiJson.load(str, symbolize_names: true)
    end

    def auth_session
      return "" if [@username, @password].any? { |e| e.nil? }
      auth = RestClient.post "#{address_port}/session", { :username=> @username, :password => @password}
      hash = parse_json(auth)
      hash[:RagiosAuthSession]
    rescue => e
      raise_error(e)
    end
  end
end
