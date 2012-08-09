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

		def execute(import_params)
			func = @destination.repository.get_function(@function_name)
			imp_list = func.get_import_parameter_list

			import_params.each do |key, value|
				imp_list.set_value(key, value)
			end

			func.execute @destination

			itr = func.get_export_parameter_list.get_parameter_field_iterator

			out = Hash.new
			while itr.has_next_field
				field = itr.next_parameter_field
				out[field.name]=field.value
			end
			
			out
		end
	end
end
