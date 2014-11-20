#!/usr/bin/ruby

require 'HTTParty'

# To request an API token, please contact support@fieldwire.net
API_TOKEN = "" # REPLACE

API_BASE_URL = "https://console.fieldwire.net/api/v2/"

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

def get(url, project_token=nil)
  response = HTTParty.get(API_BASE_URL + url, {
    headers: {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => build_auth(project_token),
    }
  })

  JSON.parse(response.body)
end

def post(url, project_token, attributes)
  response = HTTParty.post(API_BASE_URL + url, {
    body: attributes.to_json,
    headers: {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => build_auth(project_token),
    }
  })

  JSON.parse(response.body)
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

