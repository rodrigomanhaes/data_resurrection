# coding: utf-8

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

      def get_raw_data(table_name, sql_reserved_words)
        table = ::DBF::Table.new(table_name)
        result = table.map {|record|
          table.columns.map {|c|
            { generated_field_name(c.name.downcase, sql_reserved_words) => record.send(c.name.downcase) } if record
          }.
            compact.
            reduce({}) {|h, e| h.merge! e }
        }.compact.reject {|v| v.empty? }
      end

      def handle_encodings(data, encodings)
        from = encodings[:from].clone
        from = [from] unless from.kind_of? Array
        original_from = from.clone
        to = encodings[:to]
        data.each do |record|
          record.each do |k, v|
            from = original_from.clone
            ic = Iconv.new(to, from.shift)
            if v.kind_of?(String)
              value = ic.iconv(v)
              while !all_valid?(value) && !from.empty?
                ic = Iconv.new(to, from.shift)
                value = ic.iconv(v) if v.kind_of?(String)
              end
            else
              value = v
            end
            record[k] = value
          end
        end
      end

      def all_valid?(string)
        string.chars.all? {|c| VALID_CHARS.include? c }
      end

      def generated_field_name(field_name, reserved_words)
        reserved_words.include?(field_name.upcase) ? "#{field_name}_" : field_name
      end

      REGULAR_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      DIGITS = '1234567890'
      ACCENTED_LETTERS = 'ÀàÁÉÍÓÚáéíóúÂÊÔâêôÃÑÕãñõÖÜöü'
      SYMBOLS = "\"'!@#$\%&*()-_+=`{}[]^~,<>.:;/?|\\ "
      VALID_CHARS = [REGULAR_LETTERS, DIGITS, ACCENTED_LETTERS, SYMBOLS].join
    end
  end
end

