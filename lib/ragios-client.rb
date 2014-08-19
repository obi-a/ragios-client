require 'rest_client'
require 'json/pure'
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
      @username = args.fetch(:username, '')
      @password = args.fetch(:password, '')
    end

    def login(username,password)
      @username = username
      @password = password
      auth_session
    end

    def add(monitor)
      api_request { RestClient.post "#{address_port}/monitors/", generate_json(monitor), http_request_options }
    end
    def find(monitor_id)
      api_request { RestClient.get "#{address_port}/monitors/#{monitor_id}/", auth_cookie }
    end
    def all
      api_request { RestClient.get "#{address_port}/monitors/", auth_cookie }
    end
    def stop(monitor_id)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "stopped"}, http_request_options }
    end
    def restart(monitor_id)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "active"},http_request_options }
    end
    def delete(monitor_id)
      api_request { RestClient.delete "#{address_port}/monitors/#{monitor_id}", auth_cookie }
    end
    def where(options)
      api_request { RestClient.get "#{address_port}/monitors?#{URI.encode_www_form(options)}", auth_cookie }
    end
    def update(monitor_id, options)
      api_request { RestClient.put "#{address_port}/monitors/#{monitor_id}",generate_json(options), http_request_options }
    end

    def test(monitor_id)
      api_request { RestClient.post "#{address_port}/tests", {:id => monitor_id}, http_request_options }
    end

private
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
      {:cookies => {:AuthSession => auth_session}}
    end

    def http_request_options
      {:content_type => :json,
       :cookies => {:AuthSession => auth_session}
      }
    end

    def address_port
      "#{@address}:#{@port}"
    end

    def generate_json(str)
      JSON.generate(str)
    end

    def parse_json(str)
      JSON.parse(str, symbolize_names: true)
    end

    def auth_session
      auth = RestClient.post "#{address_port}/session", { :username=> @username, :password => @password}
      hash = parse_json(auth)
      hash[:AuthSession]
    rescue => e
      raise_error(e)
    end
  end
end
