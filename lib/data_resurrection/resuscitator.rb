module DataResurrection
  class Resuscitator
    def initialize(adapter_key, active_record_settings)
      extend find_adapter(adapter_key)
      ActiveRecord::Base.establish_connection(active_record_settings)
      @connection = ActiveRecord::Base.connection
    end

    private

    def find_adapter(adapter_key)
      adapter = DataResurrection::Adapter
      adapter.const_get(adapter.constants.
        select {|const_name| adapter.const_get(const_name).is_a? Module }.
        find {|a| a.to_s.underscore.to_sym == adapter_key })
    end
  end
end

