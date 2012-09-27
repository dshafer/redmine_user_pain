require_dependency 'issue'
require 'pp'
require 'rufus/scheduler'

module RedmineUserPain
  # Patches Redmine's Issues dynamically.  Adds a +after_save+ filter.
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_save :update_instance_user_pain
        #alias_method_chain :css_classes, :css_pain

        #Issue.update_all_user_pain
        
        Issue.scheduler = Rufus::Scheduler.start_new


        Issue.scheduler.every "10s" do
          logger.info("************** running UserPain updater **************")
          Issue.update_all_user_pain
        end

        logger.info("every job size is " + Issue.scheduler.every_job_count.to_s)

      end
    end

    module ClassMethods
      def scheduler=(value)
        @scheduler=value
      end
      def scheduler
        return @scheduler
      end
      def update_all_user_pain
        logger.info("\niterating through issues...")
        Issue.find(:all).each do |issue|
          begin
            issue.update_instance_user_pain
          rescue => e
            logger.info (e.message)
          end
        end
      end
    end
    
    module InstanceMethods
      def update_instance_user_pain
        begin
          # get the last custom field
          if(self.tracker.name == "Bug")
            issue_type = CustomField.find_by_name("BugType")
            issue_effect = CustomField.find_by_name("BugEffect")
          elsif(self.tracker.name == "Feature")
            issue_type = CustomField.find_by_name("FeatureType")
            issue_effect = CustomField.find_by_name("FeatureEffect")
          end
          issue_occurrence = CustomField.find_by_name("Occurrence")
          issue_impact = CustomField.find_by_name("Impact")
          if issue_occurrence && issue_type && issue_effect && issue_impact
            occurrence_values_length = issue_occurrence['possible_values'].length
            type_values_length = issue_type['possible_values'].length
            effect_values_length = issue_effect['possible_values'].length
            impact_values_length = issue_impact['possible_values'].length
            occurrence_pain = 0 
            type_pain = 0
            effect_pain = 0
            impact_pain = 0
            

            self.custom_values.each do |x|
              if (x.custom_field_id == issue_occurrence.id) && (issue_occurrence['possible_values'].index(x.value))
                occurrence_pain = occurrence_values_length - issue_occurrence['possible_values'].index(x.value)
              end
              if (x.custom_field_id == issue_type.id) && (issue_type['possible_values'].index(x.value))
                type_pain = type_values_length - issue_type['possible_values'].index(x.value)
              end
              if (x.custom_field_id == issue_effect.id) && (issue_effect['possible_values'].index(x.value))
                effect_pain = effect_values_length - issue_effect['possible_values'].index(x.value)
              end
              if (x.custom_field_id == issue_impact.id) && (issue_impact['possible_values'].index(x.value))
                impact_pain = impact_values_length - issue_impact['possible_values'].index(x.value)
              end
            end

            raw_pain = occurrence_pain * type_pain * effect_pain * impact_pain

            if raw_pain > 0
              max_pain = occurrence_values_length * type_values_length * effect_values_length * impact_values_length
              scaled_pain = user_pain_age_factor + 100 * raw_pain / max_pain
              logger.info("calculated user pain: " + scaled_pain.to_s)
              self.custom_values.each do |x|
                if (x.custom_field.name == "UserPain")
                  x.value = scaled_pain
                  x.save
                end
              end
            end
          else 
            return 0
          end
        rescue => e
          logger.info(e.message)
          return 0
        end
      end

      def user_pain_age_factor
        ageDays = ((Time.now - self.created_on) / 3600)/24
        return ageDays * 0.2
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
