module DataResurrection
  class Resuscitator
    def initialize(adapter, active_record_settings)
      extend adapters[adapter]
      ActiveRecord::Base.establish_connection(active_record_settings)
      @connection = ActiveRecord::Base.connection
    end

    def resurrect(origin_table, options)
      target_table_name, from, to = options[:target], options[:from], options[:to]
      data = get_data(origin_table, {from: from, to: to}, sql_reserved_words)
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

    def sql_reserved_words
      @sql_reserved_words ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), 'sql_reserved_words'))).
        each_line.to_a
    end
  end
end

