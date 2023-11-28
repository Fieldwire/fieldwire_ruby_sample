require_relative 'regional_client'
require_relative 'super_client'
require_relative 'token_manager'

module Fieldwire
  module SampleCalls
    module_function

    def execute(refresh_token:, access_token:, region:, email_for_project_invite:, local_file_path_for_plan:)
      token_manager = Fieldwire::TokenManager.new(
        refresh_token: refresh_token,
        access_token: access_token
      )

      execute_sample_super_calls(token_manager: token_manager)

      execute_sample_regional_calls(
        token_manager: token_manager,
        region: region,
        email_for_project_invite: email_for_project_invite,
        local_file_path_for_plan: local_file_path_for_plan
      )
    end

    # Super endpoints are used for account & users info
    private_class_method def execute_sample_super_calls(token_manager:)
      super_client = Fieldwire::SuperClient.new(token_manager: token_manager)
      users = super_client.get(url: 'account/users')

      users_info = users
        .map { |u| "#{u.dig('user', 'account_role')}: #{u.dig('user', 'email')}" }
        .sort
        .join("\n")

      log_info(purpose: 'Users in account', data: users_info)
    end

    # Regional endpoints are used for projects, templates etc.
    private_class_method def execute_sample_regional_calls(token_manager:, region:, email_for_project_invite:, local_file_path_for_plan:)
      regional_client = Fieldwire::RegionalClient.new(
        token_manager: token_manager,
        region: region
      )

      #-----------------------------------------------#
      # List projects
      #-----------------------------------------------#
      projects = regional_client.get(url: 'projects')
      projects_info = projects
        .map { |p| "#{p.fetch('id')}: #{p.fetch('name')}" }
        .sort
        .join("\n")

      log_info(purpose: 'Projects in account', data: projects_info)

      #-----------------------------------------------#
      # Create a new project
      #-----------------------------------------------#
      project = regional_client.post(
        url: 'projects',
        attributes: { name: 'New project' }
      )

      log_info(purpose: 'Created project', data: project)

      #-----------------------------------------------#
      # Invite a user to a project
      #-----------------------------------------------#
      response = regional_client.post(
        url: "projects/#{project['id']}/users/invite",
        attributes: { email: email_for_project_invite }
      )

      user = response["users"][0]
      log_info(purpose: 'Invited user to project', data: user)

      #-----------------------------------------------#
      # Add a task to a project
      #-----------------------------------------------#
      task = regional_client.post(
        url: "projects/#{project['id']}/tasks",
        attributes: {
          name: 'Todo',
          priority: 1,
          owner_user_id: user['id'],
          creator_user_id: user['id'],
          last_editor_user_id: user['id'],
        }
      )

      log_info(purpose: 'Created task', data: task)

      #-----------------------------------------------#
      # Update a task
      #-----------------------------------------------#
      task = regional_client.patch(
        url: "projects/#{project['id']}/tasks/#{task['id']}",
        attributes: {
          priority: 2,
          due_at: Time.now,
          last_editor_user_id: user['id'],
        }
      )

      log_info(purpose: 'Updated task', data: task)

      #-----------------------------------------------#
      # Upload a plan to a project. Multiple steps:
      #   - upload a plan to Fieldwire's S3 bucket
      #   - inform Fieldwire about the upload plan
      #-----------------------------------------------#
      file_url = regional_client.upload_file(
        local_file_path: local_file_path_for_plan
      )

      sheet_upload = regional_client.post(
        url: "projects/#{project['id']}/sheet_uploads",
        attributes: {
          name: File.basename(local_file_path_for_plan),
          file_url: file_url,
          file_size: File.size(local_file_path_for_plan),
          user_id: user['id']
        }
      )

      log_info(purpose: 'Plan uploaded for processing', data: sheet_upload)
    end

    private_class_method def log_info(purpose:, data:)
      puts "===============================================\n"
      puts "#{purpose}\n"
      puts data
      puts "===============================================\n\n"
    end
  end
end
