# coding: utf-8

require 'dbf'
require 'iconv'

module DataResurrection
  module Adapters
    module DBF
      def resurrect(origin_table, options)
        target_table_name, from, to = options[:target], options[:from], options[:to]
        field_types = options[:field_types]
        table = ::DBF::Table.new(origin_table)
        data = get_data(table, {from: from, to: to}, reserved_words)
        create_table(table, target_table_name, data, field_types)
        copy_data(target_table_name, data)
      end

      def get_data(table, encodings=nil, reserved_words=[])
        result = get_raw_data(table, reserved_words)
        result = handle_encodings(result, encodings) if encodings
        result
      end

      private

      def create_table(table, table_name, data, field_types)
        schema = mark_name_clashed_fields(table.schema, data)
        schema = replace_types(schema, field_types) if field_types
        eval(schema)
      end

      def copy_data(table_name, data)
        ARObject.instance_eval do
          self.table_name = table_name
          reset_column_information
        end
        data.each {|record| ARObject.create! record }
      end

      def get_raw_data(table, reserved_words)
        result = table.map {|record|
          table.columns.map {|c|
            { generated_field_name(c.name.downcase, reserved_words) => record.attributes[c.name.downcase] } if record
          }.
            compact.
            reduce({}) {|h, e| h.merge! e }
        }.compact.reject {|v| v.empty? }
      end

      def handle_encodings(data, encodings)
        from = encodings[:from].clone || []
        from = [from] unless from.kind_of? Array
        to = encodings[:to]
        data.each do |record|
          record.each do |k, v|
            if v.kind_of?(String)
              value = v
              from.each do |encoding|
                begin
                  ic = Iconv.new(to, encoding)
                  value = ic.iconv(v) if v.kind_of?(String)
                  break if all_valid?(value)
                rescue Iconv::IllegalSequence
                  raise if encoding == from.last
                end
              end
              record[k] = value
            end
          end
        end
      end

      def mark_name_clashed_fields(schema, data)
        data.first.keys.each do |field|
          if !schema.include?('column "%s"' % field)
            schema['column "%s"' % field.chop] = 'column "%s"' % field
          end
        end
        schema
      end

      def replace_types(schema, field_types)
        field_types.each do |field, new_type|
          schema =~ /column "#{field}", :(.+)/
          tail = $1.split(':')
          old_type = tail.shift
          tail = tail.empty? ? "" : ":#{tail.join(':')}"
          schema['column "%s", :%s%s' % [field, old_type, tail]] =
            'column "%s", :%s%s' % [field, new_type, tail]
        end
        schema
      end

      def all_valid?(string)
        string.chars.all? {|c| VALID_CHARS.include? c }
      end

      def generated_field_name(field_name, reserved_words)
        reserved_words.include?(field_name.upcase) ? "#{field_name}_" : field_name
      end

      class ARObject < ActiveRecord::Base
      end

      REGULAR_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      DIGITS = '1234567890'
      ACCENTED_LETTERS = 'ÀàÁÉÍÓÚáéíìóúÂÊÔâêôÃÑÕãñõÖÜöüÇç'
      SYMBOLS = "\"'!@#$\%&*()-_+=`{}[]^~,<>.:;/?|\\ "
      VALID_CHARS = [REGULAR_LETTERS, DIGITS, ACCENTED_LETTERS, SYMBOLS].join
    end
  end
end

