require 'rest-client'
require 'json'
require_relative 'super_client'

module Fieldwire
  class TokenManager
    def initialize(refresh_token:, access_token:)
      @refresh_token = refresh_token
      @access_token = access_token
    end

    # `block` will be called with the access token. If the call made fails,
    # because of bad access token (expired or invalid), this method will
    # automatically retry & try the call again
    #
    # NOTE: make sure that the passed in block can be called multiple times
    # without messing up any of your internal state (i.e., change your
    # internal state only on a successful response from the server)
    def execute_with_token(&block)
      block.call(@access_token)
    rescue RestClient::ExceptionWithResponse => err
      if err.response.code == 401
        puts 'Received 401 from the server. Trying to refresh token'

        # If the first call failed with 401, refresh the access token (since it
        # might have expired) & try again
        refresh

        puts 'Token successfully refreshed. Retrying call'
        block.call(@access_token)
      else
        # Let's bubble up all the other exceptions as is
        raise
      end
    end

    private

    def refresh
      # NOTE: In a multi-thread scenario, please make sure multiple threads
      # aren't refreshing at the same time - let the first thread do it &
      # for the other threads to use the newly acquired access token
      # (otherwise, there will be rate limit issues). May we suggest looking
      # into `Mutex` for this? (a multi-process setup would require a more
      # sophisticated system)

      attributes = { api_token: @refresh_token }
      headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      }

      response = RestClient.post(
        SuperClient::API_BASE_URL + 'api_keys/jwt',
        attributes.to_json,
        headers
      )

      # NOTE: please make sure to persist this somewhere outside the script
      # so it can reused for the next invocation of the script (otherwise,
      # there will be rate limit issues)
      @access_token = JSON.parse(response.body)['access_token']
    end
  end
end
