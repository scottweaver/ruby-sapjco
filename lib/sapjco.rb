require 'java'
require 'yaml'
require 'haml'
require 'tempfile'
require 'launchy'

#First test if the classpath already includes the SAPJCO API
begin
    require 'sapjco3.jar'
    java_import com.sap.conn.jco.ext.Environment
    puts "sapjco3.jar successfuly loaded!"
rescue Exception => e
    raise( <<-eos 
The sapjco3.jar could not be located on the classpath.  Either:
 - (easiest) Add it to you CLASSPATH environment variable.
 - Make sure it is part of the classpath of the JVM running JRuby.
 - (best) Create a ruby that contains the 'sapjco3.jar' in the /lib directory 
   and install the gem locally.
 eos
    ) 
end

require 'sap_assist.rb'

module Sap
    module Configuration
        java_import com.sap.conn.jco.ext.Environment

        def self.configure(configuration=nil)
            # configure "by hand"
            if block_given?
                @@configuration = {}
                yield @@configuration
            elsif configuration
                @@configuration = configuration
            else
                config_path = ENV['SAPJCO_CONFIG'] || 'config/sapjco.yml'
                puts "Configuring SAPJCo from #{config_path}."
                @@configuration =  YAML::load(File.open(config_path))
            end
    
            if(!Environment.destination_data_provider_registered?)
                destination_data_provider = RubyDestinationDataProvider.new(@@configuration)
                Environment.register_destination_data_provider(destination_data_provider)
            end
        end

        def self.configuration
           @@configuration 
        end

        # Create our own destination provider which converts our YAML config to a
        # java.util.Properties instance that the JCoDestinationManager can use.
        class RubyDestinationDataProvider
            include com.sap.conn.jco.ext.DestinationDataProvider
            java_import java.util.Properties
            
            def initialize(configuration)
                @destinations=configuration['destinations'] 
            end
        
            def get_destination_properties(destination_name)
                props = Properties.new
                @destinations[destination_name.to_s].each do |key, value|
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
    end

    class Function
        def initialize(function_name, destination_name)
            @function_name = function_name
            @destination = com.sap.conn.jco.JCoDestinationManager.get_destination destination_name.to_s
            @func = @destination.repository.get_function(@function_name.to_s)
        end

        # Executes the SAP RFC.  Optionally: you can pass in a block that takes
        # a hash which can be used to set the import parameter list for this function 
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
            html = engine.render DocumentationHelper.new, :metadata => metadata

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
               #info[:import?] = param.import?
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

    class DocumentationHelper
   
        def render(template_name, args)
            template = File.read("#{File.dirname(__FILE__)}/../templates/#{template_name.to_s}.haml")
            engine = Haml::Engine.new(template)
            engine.render Object.new, args 
        end
        
    end
end
