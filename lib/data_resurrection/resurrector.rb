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

    def reserved_words
      @reserved_words ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), 'reserved_words'))).
        each_line.to_a
    end
  end
end

