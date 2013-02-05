# Need makes sure the SAP implementations are loaded before we attempt to
# open then.
module Sap
  module Assist
    module MetaData
      # Convinience method that can be used to walk a SAPJCo metadta hierarchy
      def self.each(metadata, &block)
        unless metadata.nil?
          record_count = metadata.get_field_count
          (0..(record_count-1)).each do |i|
            yield(Sap::Assist::MetaData::Record.new(metadata, i))
          end
        end
      end

      # Iterates over all of the JcoRecordMetaData associated with the contained fields
      def each &block
        MetaData.each self, &block
      end

      class Record
        attr_reader :name, :type, :description

        def initialize(parent_metadata, index)
          @name = parent_metadata.get_name index ;
          @metadata = parent_metadata.get_record_meta_data index
          @type = parent_metadata.get_type_as_string index
          @description = parent_metadata.get_description index

          # @import =  parent_metadata.is_import(index) if parent_metadata.respond_to?(:is_import)
        end

        def fields?
          !@metadata.nil? && @metadata.get_field_count > 0
        end

        def each &block
          MetaData.each @metadata, &block
        end
      end
    end
  end
end


# Start rewriting ugliness
module Java
  module ComSapConnJcoRt
    class DefaultListMetaData
      include Sap::Assist::MetaData
    end

    class DefaultRecordMetaData
      include Sap::Assist::MetaData
    end

  end
end
