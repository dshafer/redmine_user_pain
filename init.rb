require 'redmine'

require 'issue_patch'
require 'query_patch'
require 'user_pain_issue_hook'

Redmine::Plugin.register :redmine_redmine_user_pain do
  name 'Redmine User Pain plugin'
  author 'Théodore Biadala'
  description 'Implement User Pain bug triage'
  version '0.0.2'
  url 'https://github.com/dshafer/redmine_user_pain'
  author_url 'http://github.com/dshafer'
end

