module DataResurrection
  class Resuscitator
    def initialize(adapter, active_record_settings)
      extend adapters[adapter]
    end

    def bring_to_life(table_name)
      data = get_data(table_name)
    end

    private

    def adapters
      @adapters ||= {:dbf => DataResurrection::Adapters::DBF }
    end
  end
end

