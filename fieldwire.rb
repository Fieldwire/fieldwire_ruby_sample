require_relative 'lib/sample_calls'
require_relative 'lib/regional_client'

# Please refer to the following links for information on getting these tokens:
#   - refresh_token: https://help.fieldwire.com/hc/en-us/articles/205097173
#   - access_token: TODO (endpoint present in developers.fieldwire.com)
#
# NOTE: `refresh_token` doesn't expire but `access_token` has an expiry on it.
# `TokenManager` knows how to get a new `access_token` (using `refresh_token`)
begin
  Fieldwire::SampleCalls.execute(
    refresh_token: '', # REPLACE
    access_token: '', # REPLACE
    email_for_project_invite: '', # REPLACE
    local_file_path_for_plan: '', # REPLACE

    # Set the region based on where you want your data to be stored. More info
    # regarding EU servers can be found here:
    # https://help.fieldwire.com/hc/en-us/articles/18799416373531
    region: Fieldwire::RegionalClient::REGION_US,
  )
rescue StandardError => err
  puts "Received error: #{err}"

  if err.respond_to?(:http_code)
    puts "  error code: #{err.http_code}"
    puts "  response body: #{err.http_body}"
  end

  puts err.backtrace
  exit(false)
end
