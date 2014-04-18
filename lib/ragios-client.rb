require 'rest_client'
require 'yajl'
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

    def add(monitors)
      response = RestClient.post "#{address_port}/monitors/", json(monitors), http_request_options
      parse_json(response.body)
    rescue => e
      raise_error(e)
    end

    def find(monitor_id)
      response = RestClient.get "#{address_port}/monitors/#{monitor_id}/", auth_cookie
      parse_json(response.body)
    rescue => e
      raise_error(e)
    end

    def all
      response = RestClient.get "#{address_port}/monitors/", auth_cookie
      parse_json(response.body)
    end

    def stop(monitor_id)
      response = RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "stopped"}, http_request_options
      parse_json(response)
    rescue => e
      raise_error(e)
    end

    def restart(monitor_id)
      response = RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "active"},http_request_options
      parse_json(response)
    rescue => e
      raise_error(e)
    end

    def delete(monitor_id)
      response = RestClient.delete "#{address_port}/monitors/#{monitor_id}", auth_cookie
      parse_json(response)
    rescue => e
      raise_error(e)
    end

    def where(options)
      response = RestClient.get "#{address_port}/monitors?#{URI.encode_www_form(options)}", auth_cookie
      parse_json(response)
    end

    def update(monitor_id, options)
      response = RestClient.put "#{address_port}/monitors/#{monitor_id}",json(options), http_request_options
      parse_json(response)
    rescue => e
      raise_error(e)
    end

    def test(monitor_id)
      response = RestClient.post "#{address_port}/tests", {:id => monitor_id}, http_request_options
      parse_json(response)
    rescue => e
      raise_error(e)
    end

private

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

    def json(str)
      Yajl::Encoder.encode(str)
    end

    def parse_json(str)
      Yajl::Parser.parse(str, :symbolize_keys => true)
    end

    def auth_session
      #deal with performance when it becomes a problem not yet a priority
      auth = RestClient.post "#{address_port}/session", { :username=> @username, :password => @password}
      hash = Yajl::Parser.parse(auth.to_str)
      hash['AuthSession']
    rescue => e
      raise_error(e)
    end
  end
end
