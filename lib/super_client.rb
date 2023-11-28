require 'rest-client'
require 'json'

module Fieldwire
  class SuperClient
    # Account & user information lives in super. It also deals with
    # generating access tokens (JWTs) for refresh tokens
    API_BASE_URL = "https://client-api.super.fieldwire.com/"

    def initialize(token_manager:)
      @token_manager = token_manager
    end

    def get(url:)
      @token_manager.execute_with_token do |token|
        response = RestClient.get(
          API_BASE_URL + url,
          build_headers(token: token)
        )

        JSON.parse(response.body)
      end
    end

    private

    def build_headers(token:)
      return {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{token}",
      }
    end
  end
end
