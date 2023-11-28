require 'rest-client'
require 'json'

module Fieldwire
  class RegionalClient
    REGION_EU = :eu
    REGION_US = :us

    # Our regional instances (EU & US) store the project data, account
    # templates, checklists etc.
    API_BASE_URL_EU = "https://client-api.eu.fieldwire.com/api/v3/"
    API_BASE_URL_US = "https://client-api.us.fieldwire.com/api/v3/"

    def initialize(token_manager:, region:)
      @token_manager = token_manager
      if region == REGION_EU
        @base_url = API_BASE_URL_EU
      elsif region == REGION_US
        @base_url = API_BASE_URL_US
      else
        raise "unrecognized FW region: #{region}"
      end
    end

    def get(url:)
      @token_manager.execute_with_token do |token|
        response = RestClient.get(
          @base_url + url,
          build_headers(token: token)
        )

        JSON.parse(response.body)
      end
    end

    def post(url:, attributes:)
      @token_manager.execute_with_token do |token|
        response = RestClient.post(
          @base_url + url,
          attributes.to_json,
          build_headers(token: token)
        )

        JSON.parse(response.body)
      end
    end

    def patch(url:, attributes:)
      @token_manager.execute_with_token do |token|
        response = RestClient.patch(
          @base_url + url,
          attributes.to_json,
          build_headers(token: token)
        )

        JSON.parse(response.body)
      end
    end

    def upload_file(local_file_path:)
      # Call Fieldwire server to receive information on where to upload to S3
      # & the associated tokens to perform the upload
      aws_post_token = post(
        url: 'aws_post_tokens',
        attributes: {}
      )

      s3_post_address = aws_post_token['post_address']
      s3_post_params = aws_post_token['post_parameters']

      # Include the path of the file to be uploaded to the acquired params
      s3_post_params[:file] = File.new(local_file_path)
      response = RestClient.post(
        s3_post_address + '/',
        s3_post_params
      )

      if (response.code == 200) || (response.code == 204)
        s3_key = s3_post_params['key'].gsub('${filename}', File.basename(local_file_path))
        return "#{s3_post_address}/#{s3_key}"
      else
        # You can have a look at https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html here
        # Mainly, 403 (forbidden) means that you have modified the attributes parameters,
        # where as 400 (bad request) can mean your token has expired, and/or you file is oversized
        return nil
      end
    end

    private

    def build_headers(token:)
      return {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{token}",
        'Fieldwire-Version' => '2023-08-08',
      }
    end
  end
end
