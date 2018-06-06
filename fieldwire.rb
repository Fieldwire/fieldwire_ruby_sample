#!/usr/bin/ruby

require 'HTTParty'
require 'rest-client'

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
  response = HTTParty.get(API_BASE_URL + url, {
    headers: build_headers(project_token)
  })

  JSON.parse(response.body)
end

def post(url, project_token, attributes)
  response = HTTParty.post(API_BASE_URL + url, {
    body: attributes.to_json,
    headers: build_headers(project_token)
  })

  JSON.parse(response.body)
end

def patch(url, project_token, attributes)
  response = HTTParty.patch(API_BASE_URL + url, {
    body: attributes.to_json,
    headers: build_headers(project_token)
  })

  JSON.parse(response.body)
end

def postToAws(url, attributes, filename)
  query = attributes.clone
  query[:file] = File.new(filename) 

  RestClient.post(url, query) 
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

aws_post_token = post("projects/#{ project["id"] }/aws_post_tokens", project["access_token"], {})
puts aws_post_token

#-----------------------------------------------#
# Post a file directly to aws using token
#-----------------------------------------------#

response = postToAws(aws_post_token['post_address'], aws_post_token['post_parameters'], "") # REPLACE
puts response

