#!/usr/bin/env ruby

module Helpers
  class Epoch
    LD = {
      # Divides two numbers, returning integer-quotient and remainder
      div_rem: ->(numerator, denominator) {
        quotient  = numerator / denominator
        remainder = numerator % denominator
        { count: quotient, remain: remainder }
      },
      octalize: ->(str_num) { str_num.to_s == '0' ? '00' : ( (str_num.to_i > 9 || str_num.match?('0')) ? str_num.to_s : "0#{str_num}" ) }
    }

    require 'date'
    require 'time'
    
    # Get an array from specified string-time ['YYYY', 'MM', 'DD', 'hh', 'mm', 'ss']
    def self.break_date(str_date)
      result = str_date.to_s.split(/[\/\-\s\,\.\:]/).map{ |ele| LD[:octalize].call(ele) }

      while result.count < 6 do
        result.append('00')
      end
      
      result
    end

    # Subtracts the given epoch (unix) time from the current unix time (in seconds)
    def self.epoch_ago(itime)
      Time.now.to_i - itime.to_f.round
    end
    
    def self.handle_date(str_date)
      date = {}
      str_date = str_date.to_s

      if str_date.match?(/[\/\-\s\,\.\:]/) or str_date.length == 8
        date[:year], date[:month], date[:day], date[:minute], date[:second] = break_date(str_date)
      else
        case str_date.length
        when 14
          date = {
            year:   str_date[0..3],
            month:  str_date[4..5],
            day:    str_date[6..7],
            hour:   str_date[8..9],
            minute: str_date[10..11],
            second: str_date[12..-1]
          }
        when 10
          date[:year], date[:month], date[:day], date[:minute], date[:second] = break_date(Time.at(str_date.to_i).to_s[0..-7])
        else
          raise ArgumentError "#{str_date} is not a valid date format."
        end
      end

      # Epoch time from the parsed date
      date[:epoch] = Time.parse(DateTime.new(*date.values.map(&:to_i)).to_s).to_i

      # Microstrain's YYYYMMDDhhmmss integer format
      date[:sensr] = date.values[0..-2].join('').to_i

      date
    end

    # Singularizes output grammar when there is only one, then combines days through seconds
    def self.report(days, hrs, mins, secs)
      d = days == 1 ? "#{days} day"    : "#{days} days"
      h = hrs  == 1 ? "#{hrs} hour"    : "#{hrs} hours"
      m = mins == 1 ? "#{mins} minute" : "#{mins} minutes"
      s = secs == 1 ? "#{secs} second" : "#{secs} seconds"
    
      if days + hrs + mins == 0
        then puts "#{s} ago."
      elsif days + hrs == 0
        then puts "#{m}, and #{s} ago."
      elsif days == 0
        then puts "#{h}, #{m}, and #{s} ago."
      else
        puts "#{d}, #{h}, #{m}, and #{s} ago."
      end
    end
    
    # Put it all together to report how long ago in words an epoch time was
    def self.words_ago_from_epoch(epoch_diff)
      clean = self.epoch_ago(epoch_diff)
      days  = LD[:div_rem].call(clean, 86400)  # Divide days, hours, minutes by seconds
      hours = LD[:div_rem].call(days[:remain], 3600)  # and save the remainders.
      mins  = LD[:div_rem].call(hours[:remain], 60)
    
      # Notice we don't divide-out seconds, just use the remainders from minutes
      self.report(days[:count], hours[:count], mins[:count], mins[:remain])
      { days: days[:count], hours: hours[:count], minutes: mins[:count], seconds: mins[:remain] }
    end
  end
end
