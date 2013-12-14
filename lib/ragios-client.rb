require 'rest_client'
require 'yajl'
require 'uri'

module Ragios
  class Client
    attr_accessor :address
    attr_accessor :port

    def initialize(address = 'http://127.0.0.1', port = '5041')
      @address = address
      @port = port
      @http_request_options = {:content_type => :json,
                               :cookies => {:AuthSession => @auth_session}}
      @auth_cookie =  {:cookies => {:AuthSession => auth_session}}
    end

    def login(username,password)
      @username = username
      @password = password
      auth_session
    end

    def add(monitors)
      RestClient.post "#{address_port}/monitors/", json(monitors), @http_request_options
    end

    def find(monitor_id)
      RestClient.get "#{address_port}/monitors/#{monitor_id}/",@auth_cookie
    end

    def all
      RestClient.get "#{address_port}/monitors/",@auth_cookie
    end

    def stop(monitor_id)
      RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "stopped"}, @http_request_options
    end

    def restart(monitor_id)
      RestClient.put "#{address_port}/monitors/#{monitor_id}",{:status => "active"},@options
    end

    def delete(monitor_id)
      RestClient.delete "#{address_port}/monitors/#{monitor_id}", @auth_cookie
    end

    def find_by(options)
      RestClient.get "#{address_port}/monitors?#{URI.encode_www_form(options)}", @auth_cookie
    end

    def update(monitor_id, options)
      RestClient.put "#{address_port}/monitors/#{monitor_id}",json(options), @http_request_options
    end

    def test(monitor_id)
      RestClient.post '#{address_port}/tests', {:id => monitor_id}, @http_request_options
    end

private
    def address_port
      "#{@address}:#{@port}"
    end

    def json(str)
      Yajl::Encoder.encode(str)
    end

    def auth_session
      #deal with performance when it becomes a problem not yet a priority
      auth = RestClient.post "#{address_port}/session", { :username=> @username, :password => @password}
      hash = Yajl::Parser.parse(auth.to_str)
      hash['AuthSession']
    end
  end
end