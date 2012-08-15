require 'java'
require 'yaml'
require 'haml'
require 'tempfile'
require 'launchy'

#First test if the classpath already includes the SAPJCO API
begin
    java_import com.sap.conn.jco.ext.Environment
    puts "SAPJCO loaded from classpath"
rescue Exception => e
#If not, load it from the environment
    jco_path = ENV['SAP_JCO_HOME']
    $:.unshift(jco_path)
    require 'sapjco3.jar'
    puts "SAPJCO loaded from environment variable: #{jco_path}"
end

require 'sap_assist.rb'

module Sap
    ROOT = File.expand_path("../..", __FILE__)
    DEFAULT_CONFIG = YAML::load(File.open(ROOT+"/config.yml"))    
    java_import com.sap.conn.jco.ext.Environment
    java_import com.sap.conn.jco.JCo
    java_import java.util.Properties
    
    def self.configure(config_path)
        yaml=  YAML::load(File.open(config_path))
    end
       
    class Jco
        def initialize(config=Sap::DEFAULT_CONFIG)
            if(!Environment.destination_data_provider_registered?)
                @@ddp = RubyDestinationDataProvider.new(config)
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
            @func = @destination.repository.get_function(@function_name.to_s)
        end

        # Executes the SAP RFC.  Optionally: you can pass in a block that takes
        # hash which can be used to set the import parameter list for thsi function 
        # call.
        def execute 

            import_params = {}
            table = {}
            yield(import_params, table) if block_given?

            raise "RFC #{@function_name.to_s} is not available on the target system." if @func.nil?

            imp_list = @func.get_import_parameter_list

            import_params.each do |key, value|              
                imp_list.set_value(key.to_s, value) 
            end

            @func.execute @destination

            out = parse_sap_record_structure @func.get_export_parameter_list
            out.merge!(parse_sap_record_structure(@func.get_table_parameter_list))
            out
        end

        def metadata
            out = {}
            #out << @func.toXML
            template = FunctionMetaData.new(@func)
            out[:function]=template.name
            out[:import_parameters]=template.import_params_info 
            out[:export_parameters]=template.export_params_info 
            out[:tables]=template.table_info
            out
        end

        def help(open=false)
            template = File.read("#{File.dirname(__FILE__)}/../templates/function_doc.haml")
            engine = Haml::Engine.new(template)
            html = engine.render Object.new, :metadata => metadata

            if open
                File.open("#{@function_name}.html", "w") do |file|
                    file.write html   
                    p "Help file path #{file.path}"
                    Launchy.open(file.path)
                end 
            else
                html
            end
                
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

    class FunctionMetaData
        
        def initialize(function)
           @template = function.get_function_template
           @import_params = @template.get_import_parameter_list
           @export_params = @template.get_export_parameter_list
           @tables = @template.get_table_parameter_list
        end

        def name
           @template.get_name 
        end

        def table_info
            parse_parameters @tables
        end

        def import_params_info
           
            parse_parameters @import_params
        end

        def export_params_info
            parse_parameters @export_params
        end

        def parse_parameters(parameter_list)
            out = {}
            parameter_list.each do |param|
               info = {}
               info[:type] = param.type
               info[:description] = param.description
               if param.fields?
                    fields = {}
                    info[:fields] = fields
                    param.each do |column|
                        fields[column.name.to_sym]={:type=>column.type, 
                            :description=>column.description}
                    end
                end
                out[param.name.to_sym]=info
            end unless parameter_list.nil?
            out
        end

    end
end
