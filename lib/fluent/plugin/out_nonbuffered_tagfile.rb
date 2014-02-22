# -*- coding: utf-8 -*-

require 'logger'

module Fluent
  class NonBufferedTagFileOutput < Output
    Fluent::Plugin.register_output('nonbuffered_tagfile', self)

    config_param :dir_root, :string
    config_param :format, :string

    def configure(conf)
      super
      @loggers = {}
    end

    def shutdown
      @loggers.values.each do |logger|
        logger.close
      end
    end

    def emit(tag, es, chain)
      chain.next
      es.each {|time, record|
        get_logger(tag).info(eval(@format))
      }
    end

    def get_logger(tag)
      @loggers[tag] ||= begin
        tag_elems = tag.split('.')
        tag_elems.shift  # remove PREFIX

        raise ConfigError, "Make sure the plugin requires input records to have at least two period-delimited tag parts"\
          unless tag_elems.size > 0

        filename = tag_elems.pop

        dir =
          if tag_elems.size > 0
            File.join(@dir_root, *tag_elems).tap{|f|
              FileUtils.mkdir_p f
            }
          else
            @dir_root
          end

        path = File.join(dir, filename)

        Logger.new(path, 'daily').tap {|logger|
          logger.formatter = proc {|severity, datetime, progname, msg|
            "#{msg}\n"
          }
        }
      end
    end
  end
end
