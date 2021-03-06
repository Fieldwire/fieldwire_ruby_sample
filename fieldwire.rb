#!/usr/bin/ruby

require 'rest-client'
require 'json'

# To request an API token, please contact support@fieldwire.net
API_TOKEN = "" # REPLACE

API_BASE_URL = "https://console.fieldwire.net/api/v3/"

#-----------------------------------------------#
# Helper methods
#-----------------------------------------------#

def build_auth(project_token)
  auth = "Token api=#{ API_TOKEN }"
  if project_token
    auth += ", project=#{project_token}"
  end

  auth
end

def build_headers(project_token)
  return {
    "Content-Type" => "application/json",
    "Accept" => "application/json",
    "Authorization" => build_auth(project_token),
  }
end

def get(url, project_token=nil)
  response = RestClient.get(API_BASE_URL + url,
    build_headers(project_token)
  )

  JSON.parse(response.body)
end

def post(url, project_token, attributes)
  response = RestClient.post(API_BASE_URL + url,
    attributes.to_json,
    build_headers(project_token)
  )

  JSON.parse(response.body)
end

def patch(url, project_token, attributes)
  response = RestClient.patch(API_BASE_URL + url,
    attributes.to_json,
    build_headers(project_token)
  )

  JSON.parse(response.body)
end

def post_to_aws(url, attributes, filename)
  query = attributes.clone
  file = File.new(filename)
  query[:file] = file

  response = RestClient.post(url + '/', query)
  if (response.code == 200) || (response.code == 204)
    return "#{url}/#{attributes['key'].gsub('${filename}',File.basename(filename))}" 
  else
    # You can have a look at https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html here
    # Mainly, 403 (forbidden) means that you have modified the attributes parameters, 
    # where as 400 (bad request) can mean your token has expired, and or you file is oversized
    return nil
  end
end


#-----------------------------------------------#
# List projects
#-----------------------------------------------#

puts get("projects")

#-----------------------------------------------#
# Create a new project
#-----------------------------------------------#

project = post("projects", nil, { name: "New project" })
puts project

#-----------------------------------------------#
# Invite a user
#-----------------------------------------------#

response = post("projects/#{ project["id"] }/users/invite", project["access_token"], { email: "" }) # REPLACE
user = response["users"][0]
puts user

#-----------------------------------------------#
# Add a task
#-----------------------------------------------#

task = post("projects/#{ project["id"] }/tasks", project["access_token"],
  {
    name: "Todo",
    priority: 1,
    owner_user_id: user["id"],
    is_local: false,
  }
)

puts task

#-----------------------------------------------#
# Update a task
#-----------------------------------------------#

task = patch("projects/#{ project["id"] }/tasks/#{ task["id"] }", project["access_token"],
  {
    priority: 2,
    due_at: Time.now
  }
)

puts task

#-----------------------------------------------#
# Get a token to post a file directly to aws 
#-----------------------------------------------#

aws_post_token = post("aws_post_tokens", nil, {})
puts aws_post_token

#-----------------------------------------------#
# Post a file directly to aws using token
#-----------------------------------------------#

file_name = "" # REPLACE
response = post_to_aws(aws_post_token['post_address'], aws_post_token['post_parameters'], file_name) 

file_url = response

if file_url
  sheet_upload = post("projects/#{ project["id"] }/sheet_uploads", project["access_token"],
    {
      "name": File.basename(file_name), 
      "file_url": file_url,
      "file_size": File.size(file_name),
      "user_id": user["id"]
    }
  )
  puts "======================="

  puts sheet_upload
end

