require 'chronic'

module Tempo
  module Controllers
    class Start < Tempo::Controllers::Base
      @projects = Model::Project
      @time_records = Model::TimeRecord

      class << self

        def start_timer( options, args )

          if not options[:at]
            time_in = Time.new()
          else
            time_in = Chronic.parse options[:at]
          end

          Tempo::Views.no_match( "valid timeframe", options[:at], false ) if not time_in

          params = { start_time: time_in }
          params[:description] = reassemble_the args

          if options[:end]
            time_out = Chronic.parse options[:end]
            Tempo::Views.no_match( "valid timeframe", options[:end], false ) if not time_out
            params[:end_time] = time_out
          end

          @time_records.load_last_day
          record = @time_records.new(params)
          @time_records.save_to_file

          Tempo::Views.time_record_view( record, {new_record: true} )

        end

      end #class << self
    end
  end
end
