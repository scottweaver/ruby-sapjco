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

        def execute 

            import_params = {}
            yield(import_params)

            func = @destination.repository.get_function(@function_name.to_s)

            raise "RFC #{@function_name.to_s} is not available on the target system." if func.nil?

            imp_list = func.get_import_parameter_list

            import_params.each do |key, value|              
                imp_list.set_value(key.to_s, value) 
            end

            func.execute @destination

            out = parse_fields func.get_export_parameter_list
    
            out
        end

        def parse_fields(field_list)
            out = Hash.new
            field_list.each do |field|
                field.value.class.include?(com.sap.conn.jco.JCoStructure)
                if  field.value.class.include?(com.sap.conn.jco.JCoStructure)
                    out[field.name.to_sym] = parse_fields field.value 
                else
                    out[field.name.to_sym] = field.value 
                end
            end
            out
        end
    end
end
