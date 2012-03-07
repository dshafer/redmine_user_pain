# Hooks to attach to the Redmine Issues.
class UserPainIssueHook  < Redmine::Hook::ViewListener

  # Renders the Deliverable subject
  #
  # Context:
  # * :issue => Issue being rendered
  #
  def view_issues_show_details_bottom(context = { })
    if(context[:issue].user_pain)
      data = "<tr><td><b>#{l(:user_pain)}:</b></td><td>#{context[:issue].user_pain}</td></tr>"
      data += "<tr><td><b>#{l(:user_pain_age_factor)}:</b></td><td>#{context[:issue].user_pain_age_factor}</td></tr>"
      return "#{data}"
    end
  end

end
