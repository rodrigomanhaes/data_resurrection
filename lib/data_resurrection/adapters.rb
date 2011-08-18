require 'dbf'
require 'iconv'

module DataResurrection
  module Adapters
    module DBF
      def get_data(table_name, encodings=nil, sql_reserved_words=[])
        result = get_raw_data(table_name, sql_reserved_words)
        result = handle_encodings(result, encodings) if encodings
        result
      end

      private

      ENCODINGS = {:utf8 => 'UTF-8', :win1252 => 'WINDOWS-1252'}

      def get_raw_data(table_name, sql_reserved_words)
        table = ::DBF::Table.new(table_name)
        table.map do |record|
          table.columns.map {|c| { generated_field_name(c.name.downcase, sql_reserved_words) => record.send(c.name.downcase) }}.
            reduce({}) {|h, e| h.merge! e }
        end
      end

      def handle_encodings(data, encodings)
        ic = Iconv.new(ENCODINGS[encodings.end], ENCODINGS[encodings.begin])
        data.each do |record|
          record.each do |k, v|
            record[k] = ic.iconv(v) if v.kind_of?(String)
          end
        end
      end

      def generated_field_name(field_name, reserved_words)
        reserved_words.include?(field_name.upcase) ? "#{field_name}_" : field_name
      end
    end
  end
end

