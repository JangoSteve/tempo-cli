# simplified models, with additional display information, used in views.
#
# Each viewrecord has a :type, which can be queried in the view to know
# what type of record it is managing.
#
# They also each have a format method, which accept a block, and also includes a default
# block which returns a basic formatted string.
#
# They have no logic, and so it is up
# to the creation method to make sure they are a correct copy of the information
# they are representing.

module Tempo
  module Views
    module ViewRecords

      class Message
        attr_accessor :type, :message, :category

        def initialize message, options={}
          @message = message
          @category = options.fetch( :category, :info )
          @type = "message"
        end

        def format &block
          block ||= lambda {|m| "#{m.message}"}
          block.call self
        end
      end

      class Duration
        attr_accessor :type, :seconds

        def initialize seconds=0
          @type = "duration"
          @seconds = seconds
        end

        def format &block
          block ||= lambda do |seconds|
            hours = ( seconds / 3600 ).to_i
            minutes = ( seconds / 60 - hours * 60 ).to_i
            "#{ hours.to_s }:#{ minutes.to_s.rjust(2, '0') }"
          end
          block.call seconds
        end

        def add seconds
          @seconds += seconds
        end

        def subtract seconds
          @seconds -= seconds
        end
      end

      class Model
        attr_accessor :id, :type

        def initialize model, options={}
          @id = model.id

          # example: Tempo::Model::Something => "something"
          @type = /Tempo::Model::(.*)$/.match( model.class.to_s )[1].downcase
        end

        def format &block
          block ||= lambda {|model| "#{ model.type.capitalize} #{model.id}"}
          block.call self
        end
      end

      class Log < ViewRecords::Model
        attr_accessor :start_time, :d_id

        def initialize model, options={}
          super model, options
          @start_time = model.start_time
          @d_id = model.d_id
        end

        def format &block
          block ||= lambda {|model| "#{ model.type.capitalize} #{model.d_id}-#{model.id} #{model.start_time.strftime('%H:%M')}"}
          block.call self
        end
      end

      class TimeRecord < ViewRecords::Log
        attr_accessor :description, :duration, :end_time, :project, :running

        class << self
          def max_description_length len=0
            @max_description_length ||= 0
            @max_description_length = @max_description_length > len ? @max_description_length : len
          end

          def max_project_length len=0
            @max_project_length ||= 0
            @max_project_length = @max_project_length > len ? @max_project_length : len
          end
        end

        def initialize model, options={}
          super model, options
          @description = model.description
          @duration = Duration.new model.duration
          @end_time = model.end_time == :running ? Time.now() : model.end_time
          @project = model.project_title
          @running = model.running?
          self.class.max_description_length @description.length
          self.class.max_project_length @project.length
        end

        def format &block
          block ||= lambda do |m|
            running = m.running ? "*" : " "
            description = @description ? "#{m.project}: #{m.description}" : "#{m.project}"
            "#{m.start_time.strftime('%H:%M')} - #{m.end_time.strftime('%H:%M')}#{running} [#{m.duration.format}] #{description}"
          end
          block.call self
        end
      end

      class Composite < ViewRecords::Model
        attr_accessor :depth

        class << self
          def max_depth depth=0
            @max_depth ||= 0
            @max_depth = @max_depth > depth ? @max_depth : depth
          end
        end

        def initialize model, options={}
          super model, options
          @depth = options.fetch(:depth, 0)
          self.class.max_depth @depth
        end

        def format &block
          block ||= lambda {|model| "#{"  " * model.depth}#{ model.type.capitalize} #{model.id}"}
          block.call self
        end
      end

      class Project < ViewRecords::Composite
        attr_accessor :title, :tags, :duration

        class << self
          def max_title_length len=0
            @max_title_length ||= 0
            @max_title_length = @max_title_length > len ? @max_title_length : len
          end
        end

        def initialize model, options={}
          super model, options
          @title = model.title
          @tags = model.tags
          @duration = Duration.new
          self.class.max_title_length @title.length
        end
      end
    end
  end
end