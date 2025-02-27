# encoding: ascii-8bit

# Copyright 2022 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder

require 'cosmos'
require 'cosmos/utilities/authentication'
require 'cosmos/io/json_drb'

require 'thread'
require 'socket'
require 'json'
# require 'drb/acl'
require 'drb/drb'
require 'uri'
require 'httpclient'


module Cosmos

  # Used to forward all method calls to the remote server object. Before using
  # this class ensure the remote service has been started in the server class:
  #
  #   json = JsonDrb.new
  #   json.start_service('127.0.0.1', 7777, self)
  #
  # Now the JsonDRbObject can be used to call server methods directly:
  #
  #   server = JsonDRbObject('http://cosmos-cmd-tlm-api:2901', 1.0, '/cosmos-api/api')
  #   server.cmd(*args)
  #
  class JsonDRbObject
    attr_reader :request_data
    attr_reader :response_data

    # @param url [String] The url of cosmos-cmd-tlm-api http://cosmos-cmd-tlm-api:2901
    # @param timeout [Float] The time to wait before disconnecting 1.0
    # @param authentication [CosmosAuthentication] The authentication object if nill initialize will generate
    def initialize(url: ENV['COSMOS_API_URL'], timeout: 1.0, authentication: nil)
      @id = 0
      @http = nil
      @mutex = Mutex.new
      @request_data = ""
      @response_data = ""
      @log = [nil, nil, nil]
      @uri = URI("#{url}/cosmos-api/api")
      @authentication = authentication.nil? ? CosmosAuthentication.new() : authentication
      @timeout = timeout
      @shutdown = false
    end

    # Disconnects from http server
    def disconnect
      @http.reset_all() if @http
      @http = nil
    end

    # Permanently disconnects from the http server
    def shutdown
      @shutdown = true
      disconnect()
    end

    # Forwards all method calls to the remote service.
    #
    # @param method_name [Symbol] Name of the method to call
    # @param method_params [Array] Array of parameters to pass to the method
    # @param keyword_params [Hash<Symbol, Variable>] Hash of keyword parameters
    # @return The result of the method call. If the method raises an exception
    #   the same exception is also raised. If something goes wrong with the
    #   protocol a DRb::DRbConnError exception is raised.
    def method_missing(method_name, *method_params, **keyword_params)
      raise DRb::DRbConnError, "Shutdown" if @shutdown
      @mutex.synchronize do
        for attempt in 1..3
          @log = [nil, nil, nil]
          connect() if !@http
          json_rpc_request = JsonRpcRequest.new(method_name, method_params, keyword_params, @id)
          data = json_rpc_request.to_json(:allow_nan => true)
          response_body = make_request(data: data)
          if !response_body or response_body.to_s.length < 1
            disconnect()
          else
            response = JsonRpcResponse.from_json(response_body)
            return handle_response(response: response)
          end
        end
        error = "#{attempt} no response from server: #{@log[0]} ::: #{@log[1]} ::: #{@log[2]}"
        raise DRb::DRbConnError, error
      end
    end

    private

    def connect
      begin
        @http = HTTPClient.new
        @http.connect_timeout = @timeout
        @http.receive_timeout = nil # Allow long polling
      rescue => e
        raise DRb::DRbConnError, e.message
      end
    end

    # 
    def make_request(data:)
      headers = {
        'Content-Type' => 'application/json-rpc',
        'User-Agent' => 'Cosmos / 5.0.0 (ruby/cosmos/lib/io/json_drb_object)',
        'Authorization' => @authentication.token(),
      }
      begin
        @log[0] = "Request: #{@uri.to_s} #{headers.to_s} #{data.to_s}"
        STDOUT.puts @log[0] if JsonDRb.debug?
        resp = @http.post(@uri, :body => data, :header => headers)
        @log[1] = "Response: #{resp.status} #{resp.headers} #{resp.body}"
        @response_data = resp.body
        STDOUT.puts @log[1] if JsonDRb.debug?
        return resp.body
      rescue => e
        @log[2] = "Exception: #{e.class}, #{e.message}, #{e.backtrace}"
      end
    end

    #
    def handle_response(response:)
      # The code below will always either raise or return breaking out of the loop
      if JsonRpcErrorResponse === response
        if response.error.data
          raise Exception.from_hash(response.error.data)
        else
          raise "JsonDRb Error (#{response.error.code}): #{response.error.message}"
        end
      else
        return response.result
      end
    end
  end # class JsonDRbObject
end # module Cosmos
