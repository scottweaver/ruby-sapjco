ROOT = File.expand_path("../..", __FILE__)

require "java"
require "yaml"
require "#{ROOT}/sapjco3.jar"
java_import java.util.Properties
java_import com.sap.conn.jco.ext.Environment
java_import com.sap.conn.jco.JCo

module Sap

    class Jco
    
        def initialize
            if(!Environment.destination_data_provider_registered?)
                @@ddp = RubyDestinationDataProvider.new(YAML::load(File.open(ROOT+"/config.yml")))
                Environment.register_destination_data_provider(@@ddp)
            end
            
        end
    
        def destination_data_provider
            @@ddp
        end
    
        def connect(destination_name)
            JCo.destination_manager.get_destination_instance(destination_name, nil)
        end
        
    end
    
    # Create our own destination provider which convert our YAML config to a
    # java.util.Properties instance that the JCoDestinationManager can user.
    class RubyDestinationDataProvider
        include com.sap.conn.jco.ext.DestinationDataProvider
    
        def initialize(yaml)
            @yaml=yaml 
        end
    
        def get_destination_properties(destination_name)
            props = Properties.new
            @yaml[destination_name].each do |key, value|
                props.put(key,value)
            end
            props
        end
    
        def supports_events()
            false
        end
    
        def set_destination_data_event_listener=(eventListener)
    
        end
    end
    
    class Function

        def initialize(function_name, destination)
            @function_name = function_name
            @destination = destination
        end

        # Executes the SAP RFC.  Optionally: you can pass in a block that takes
        # hash which can be used to set the import parameter list for thsi function 
        # call.
        def execute 

            import_params = {}
            table = {}
            yield(import_params, table) if block_given?

            func = @destination.repository.get_function(@function_name.to_s)

            raise "RFC #{@function_name.to_s} is not available on the target system." if func.nil?

            imp_list = func.get_import_parameter_list

            import_params.each do |key, value|              
                imp_list.set_value(key.to_s, value) 
            end

            func.execute @destination

            out = parse_sap_record_structure func.get_export_parameter_list
            out.merge!(parse_sap_record_structure(func.get_table_parameter_list))
            out
        end

        # Recursively converts JCoRecord types to Ruby Hashes and Arrays (JCoTable instances).
        def parse_sap_record_structure(field_list)
            out = Hash.new
            field_list.each do |field|
                if field.value.class.include?(com.sap.conn.jco.JCoTable) 
                    table = field.get_table
                    table_array = []
                    begin
                        table_array << parse_sap_record_structure(table)
                    end while table.next_row
                    out[field.name.to_sym] = table_array
                elsif  field.value.class.include?(com.sap.conn.jco.JCoRecord)
                    out[field.name.to_sym] = parse_sap_record_structure field.value 
                else
                    out[field.name.to_sym] = field.value 
                end
            end unless field_list.nil?
            out
        end
    end
end
