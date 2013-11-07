require 'chronic'

module Tempo
  module Controllers
    class End < Tempo::Controllers::Base
      @projects = Model::Project
      @time_records = Model::TimeRecord

      class << self

        def end_timer options, args

          return Views.project_assistance if Model::Project.index.empty?

          if not options[:at]
            time_out = Time.new()
          else
            begin
              time_out = Chronic.parse options[:at]
            rescue
              time_out = nil
            end
          end

          Views.no_match( "valid timeframe", options[:at], false ) if not time_out

          options = { end_time: time_out }
          options[:description] = reassemble_the args

          @time_records.load_last_day
          record = @time_records.current

          return Views.no_items( "running time records", :error ) if ! record

          record.end_time = time_out
          record.description = options[:description] if options[:description]
          @time_records.save_to_file

          Views.end_time_record_view record

        end

      end #class << self
    end
  end
end
