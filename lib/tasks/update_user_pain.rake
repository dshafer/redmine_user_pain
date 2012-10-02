# vim:ts=2:autoindent:expandtab
require 'rubygems'
require 'rufus/scheduler'

namespace :redmine_user_pain do
  desc 'Re-calculate the user pain metric for all bugs'
  task :update_all => :environment do
    scheduler = Rufus::Scheduler.start_new

    scheduler.every '4h' do
      logger.info("executing scheduled user pain recalculation")
      Issue.update_all_user_pain
    end

    scheduler.join
  end
end
