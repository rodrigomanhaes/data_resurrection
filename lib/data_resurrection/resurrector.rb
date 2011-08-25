module DataResurrection
  class Resuscitator
    def initialize(adapter, active_record_settings)
      extend adapters[adapter]
      ActiveRecord::Base.establish_connection(active_record_settings)
      @connection = ActiveRecord::Base.connection
    end

    private

    def adapters
      @adapters ||= {:dbf => DataResurrection::Adapters::DBF }
    end

    def sql_reserved_words
      @sql_reserved_words ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), 'sql_reserved_words'))).
        each_line.to_a
    end
  end
end

