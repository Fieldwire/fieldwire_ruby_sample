# fieldwire_ruby_sample

Sample ruby code to integrate with Fieldwire:
  - [fieldwire.rb](fieldwire.rb) is the entry point
  - [lib](lib/) showcases the following:
    - How to call our [super endpoints](lib/super_client.rb)? (accounts, users etc.)
    - How to call out US or EU [regional endpoints](lib/regional_client.rb) (projects, templates etc.)
    - How to [refresh access tokens programmatically](lib/token_manager.rb) when they expire
    - How to put all of these together for [particular use cases](lib/sample_calls.rb)

### Setup
- Install the required ruby version (from `.ruby-version`) (ex: using [rbenv](https://github.com/rbenv/rbenv))
- Install the dependencies using `bundle install`
- Fill out the required pieces of info in [fieldwire.rb](fieldwire.rb) (Marked with `# REPLACE`)
- Run script using `bundle exec ruby fieldwire.rb`

### Note
Please store your tokens securely & use them across invocations of your integration setup to prevent hitting rate limits while refreshing the access token
