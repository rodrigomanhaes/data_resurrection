module DataResurrection
  class Resuscitator
    def initialize(adapter, active_record_settings)
      extend adapters[adapter]
      ActiveRecord::Base.establish_connection(active_record_settings)
      @connection = ActiveRecord::Base.connection
    end

    def resurrect(origin_table, options)
      target_table_name, encodings = options[:target], options[:encodings]
      data = get_data(origin_table, encodings)
      create_table(target_table_name, data)
      copy_data(target_table_name, data)
    end

    private

    def create_table(table_name, data)
      @connection.execute(
        "CREATE TABLE #{table_name} (" +
          data.first.keys.map {|field| "#{field} VARCHAR(255)," }.join.chop +
          ")")
    end

    def copy_data(table_name, data)
      data.each do |record|
        keys = record.keys
        @connection.execute <<-SQL
          INSERT INTO #{table_name}
            (#{keys.join(',')})
            VALUES (#{keys.map {|k| "'" + record[k].to_s + "'" }.join(',')})
        SQL
      end
    end

    def adapters
      @adapters ||= {:dbf => DataResurrection::Adapters::DBF }
    end
  end
end

