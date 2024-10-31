#!/usr/bin/env ruby

module Helpers
  class Sensr
    require_relative 'epoch-helpers'
    attr_reader :data_files, :name, :PID, :proof

    Color = {
      cyan: "\033[38;5;31m",
      end: "\033[0m",
      green: "\033[38;5;34m"
    }.freeze

    Projects = {
      S: { PID: 20074, short_name: 'SpaceX', path: '20074/data', proof: '20074/proof.md', proof2: '20074/proof2.md' },
      M: { PID: 17768, short_name: 'Meadowlands', path: 'test/thread_test', proof: 'proof.md' }
    }.freeze

    LD = {
      Name:             -> (var)              { "#{Color[:green]}#{var}#{Color[:end]}"                                                  },
      PID:              -> (var)              { "#{Color[:cyan]}#{var}#{Color[:end]}"                                                   },
      Proof:            -> (var)              { "#{Color[:green]}Proof.md:#{Color[:end]}\n  Date:#{Color[:cyan]} #{var}#{Color[:end]}"  },
      count_files_date: -> (date, data_files) { data_files.select{|row| row[:updated].split(/\s/)[0].match?(date)}.count                },
      data_type:        -> (path)             { path.match?('accel') ? 'acceleration' : 'sensor'                                        },
      file_stamp:       -> (path)             { path.match?('test/') ? path[28..38].to_i : path[37..52].to_i                            },
      proof:            -> (proof)            { `aws s3 ls s3://cpp-sensr/#{proof}`.split(/\s+/)                                        },
      sensor_id:        -> (path)             { path.match?('test/') ? path[23..27].to_i : path[15..19].to_i                            }
    }

    def initialize(path_key)
      throw 'Select a valid :path_key: [M, S]' unless [:M, :S].include?(path_key) 

      # Fetch the data-file names from s3
      @data_files = score_string(`aws s3 ls s3://cpp-sensr/#{Projects[path_key][:path]} --recursive`.split(/\n/))
      @name       = Projects[path_key][:short_name]
      @proof      = LD[:proof].call(Projects[path_key][:proof])
      path_key == :S ? @proof2 = LD[:proof].call("#{Projects[path_key][:proof2]}") : nil
      @pid        = Projects[path_key][:PID]
    end

    def day_report
      days     = @data_files.map{|row| row[:updated].split(/\s/)[0]}.uniq
      day_data = []

      days.each do |d|
        day_data.append(date: d, count: LD[:count_files_date].call(d, @data_files))
      end

      printf "Data:\n"
      day_data.sort_by{|h| h[:date]}
    end

    # Turn the AWS api query-result into a list of labeled hashes
    def score_string(aws_blob)
      aws_blob[-1].match?('test/') ? slug = ' test' : slug = ' 20074'  # Match path style for replacement

      # Split on size and path, return a hash with labeled elements sorted on the path
      aws_blob.map! do |row|
        cols = row.gsub(slug, " #{slug}").split(/\s\s+/)

        {
          data_type:  LD[:data_type].call(cols[2]),
          file_stamp: LD[:file_stamp].call(cols[2]),
          path:       cols[2],
          sensor_id:  LD[:sensor_id].call(cols[2]),
          size:       cols[1],
          updated:    cols[0],
        }
      end.sort_by!{ |row| row[:path] }
    end

    # Prepare the proof-file-report by the name of the proof
    def proof_report(proof_name, result)
      printf "#{proof_name}.md was last synced to AWS "
      result.merge!({proof_name.to_sym =>
        Helpers::Epoch.words_ago_from_epoch(
          Time.new(instance_variable_get("@#{proof_name}")[0..1].join(' ')).to_i
        )
      })
    end

    # Report how many files for each day, and how long since the proof file was updated
    def report
      %i[Name PID Proof Date].each do |r|
        case r
        when :Date
          pp day_report
        when :Proof
          printf "#{r}: #{LD[r].call(instance_variable_get("@#{r.downcase}")[0..1].join(' '))}\n"
        else
          printf "#{r}: #{LD[r].call(instance_variable_get("@#{r.downcase}"))}\n"
        end
      end

      result = {}  # A place to hold the time since proof was touched

      ['proof', 'proof2'].each do |p|
        next if instance_variable_get("@#{p}").nil?

        proof_report(p, result)
      end

      result[:data] = Helpers::Epoch.words_ago_from_epoch(
        Helpers::Epoch.handle_date(@data_files.last[:file_stamp])[:epoch]
      )

      result
    end
  end
end
