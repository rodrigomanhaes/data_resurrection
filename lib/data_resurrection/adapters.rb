require 'dbf'

module DataResurrection
  module Adapters
    module DBF
      def get_data(table_name)
        table = ::DBF::Table.new(table_name)
        table.map do |record|
          table.columns.map {|c| { c.name.downcase => record.send(c.name.downcase) }}.
            reduce({}) {|h, e| h.merge! e }
        end
      end
    end
  end
end

