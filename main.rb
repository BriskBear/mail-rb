#!/usr/bin/env ruby

require_relative 'lib/environment'
require_relative 'lib/mailer'
require_relative 'lib/sensr-stat'

Projects = {
  M: { client: 'Meadowlands', PID: 18881 },
  S: { client: 'SpaceX',      PID: 20074 }
}

recipients = %w[sensr-team@cppwind.com]

while true do
  Projects.each_key do |prj|
    result = Helpers::Sensr.new(prj).report
    result.each_key do |key|
      hours = result[key][:days] * 24 + result[key][:hours]
  
      next unless hours > 2
  
      Mailer.notification(Projects[prj][:client], hours, recipients, key.to_s).deliver!
      printf "\033[38;5;34mSent #{Projects[prj][:client]}:#{key.to_s.gsub('proof', '')} message\033[0m\n"
    end
  end

  sleep 5400
end
