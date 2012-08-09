ROOT = File.expand_path("../..", __FILE__)

require "java"
require "yaml"
require "#{ROOT}/sapjco3.jar"
java_import java.util.Properties
java_import com.sap.conn.jco.ext.Environment

class Jco

	attr_reader :config

	def initialize
		@config = YAML::load(File.open(ROOT+"/config.yml"))
		Environment.register_destination_data_provider(DestinationDataProvider.new)
	end
	
end

class DestinationDataProvider
	include com.sap.conn.jco.ext.DestinationDataProvider

	def destination_properties
		
	end

	def supports_events
		false		
	end

	def destination_data_eventListener=
	end
	
end