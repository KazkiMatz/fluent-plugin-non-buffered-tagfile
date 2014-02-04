# -*- coding: utf-8 -*-

#TODO: Implement log rotation

module Fluent
  class NonBufferedTagFileOutput < Output
    Fluent::Plugin.register_output('nonbuffered_tagfile', self)

    config_param :dir_root, :string
    config_param :format, :string

    def configure(conf)
      super
      @files = {}
    end

    def shutdown
      @files.values.each do |f|
        f.close
      end
    end

    def emit(tag, es, chain)
      chain.next
      es.each {|time, record|
        get_file(tag).write(eval(@format) + "\n")
      }
    end

    def get_file(tag)
      @files[tag] ||= begin
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
        File.open(path, 'a')
      end
    end
  end
end
