module DataResurrection
  class Resuscitator
    def initialize(adapter, active_record_settings)
      extend adapters[adapter]
      @active_record_settings = active_record_settings
    end

    def bring_to_life(table_name)
      data = get_data(table_name)
    end

    def create_table(table_name, data)
      ActiveRecord::Base.establish_connection(@active_record_settings)
      ActiveRecord::Base.connection.execute(
        "CREATE TABLE #{table_name} (" +
          data.first.keys.map {|field| "#{field} VARCHAR(255)," }.join.chop +
          ")")
    end

    def copy_data(table_name, data)
      ActiveRecord::Base.establish_connection(@active_record_settings)
      connection = ActiveRecord::Base.connection
      data.each do |record|
        keys = record.keys
        connection.execute <<-SQL
          INSERT INTO #{table_name}
            (#{keys.join(',')})
            VALUES (#{keys.map {|k| "'" + record[k].to_s + "'" }.join(',')})
        SQL
      end
    end

    private

    def adapters
      @adapters ||= {:dbf => DataResurrection::Adapters::DBF }
    end
  end
end

