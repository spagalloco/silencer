module Silencer
  RailsLogger = if Silencer::Environment.rails2?
    require 'rails/rack/log_tailer'
    ::Rails::Rack::LogTailer
  else
    require 'rails/rack/logger'
    ::Rails::Rack::Logger
  end

  module Rails
    class Logger < RailsLogger
      include Silencer::Util
      include Silencer::Hush

      def initialize(app, *args)
        opts     = extract_options!(args)
        @silence = wrap(opts.delete(:silence))
        @routes  = {
          'OPTIONS' => wrap(opts.delete(:options)) + @silence,
          'GET'     => wrap(opts.delete(:get)) + @silence,
          'HEAD'    => wrap(opts.delete(:head)) + @silence,
          'POST'    => wrap(opts.delete(:post)) + @silence,
          'PUT'     => wrap(opts.delete(:put)) + @silence,
          'DELETE'  => wrap(opts.delete(:delete)) + @silence,
          'TRACE'   => wrap(opts.delete(:trace)) + @silence,
          'CONNECT' => wrap(opts.delete(:connect)) + @silence,
          'PATCH'   => wrap(opts.delete(:patch)) + @silence,
        }

        super app, *args
      end

      def call(env)
        old_logger_level     = ::Rails.logger.level
        ::Rails.logger.level = ::Logger::ERROR if silence_request?(env)

        super
      ensure
        # Return back to previous logging level
        ::Rails.logger.level = old_logger_level
      end

      private

      def normalize(args)
        args = case args.size
        when 0 then nil
        when 1 then args.shift
        else args
        end
      end
    end
  end
end
