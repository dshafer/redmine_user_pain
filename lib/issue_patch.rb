require_dependency 'issue'
require 'pp'

module RedmineUserPain
  # Patches Redmine's Issues dynamically.  Adds a +after_save+ filter.
  module IssuePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :css_classes, :css_pain
      end
    end
    
    module InstanceMethods
      def user_pain
        # get the last custom field
        issue_likelihood = CustomField.find_by_name("Likelihood")
        issue_type = CustomField.find_by_name("Type")
        issue_effect = CustomField.find_by_name("Effect")
        if issue_likelihood && issue_type && issue_effect
          likelihood_values_length = issue_likelihood['possible_values'].length
          type_values_length = issue_type['possible_values'].length
          effect_values_length = issue_effect['possible_values'].length
          likelihood_pain = 1
          type_pain = 1
          effect_pain = 1
          

          # add likelihood value to total pain
          self.custom_values.each do |x|
            if x.custom_field_id == issue_likelihood.id
              likelihood_pain *= likelihood_values_length - issue_likelihood['possible_values'].index(x.value)
            end
            if x.custom_field_id == issue_type.id
              type_pain *= type_values_length - issue_type['possible_values'].index(x.value)
            end
            if x.custom_field_id == issue_effect.id
              effect_pain *= effect_values_length - issue_effect['possible_values'].index(x.value)
            end
          end

          # add type value to total pain
          pain = likelihood_pain * type_pain * effect_pain

          max_pain = likelihood_values_length * type_values_length * effect_values_length
          return 100 * pain / max_pain
        else 
          return 0
        end
      end

      def user_pain_age_factor
        ageHours = (Time.now - self.created_on) / 3600
        return ageHours
        return self.public_methods.sort.join("\n")
      end
      
      def validate_on_update
        #flash[:notice] = "validation refused by pre-save hook"
        #return false
      end
      
      def css_classes_with_css_pain
       s = css_classes_without_css_pain << " user_pain-#{self.user_pain}" 
       return s
      end

    end    

  end
end

Issue.send(:include, RedmineUserPain::IssuePatch)
