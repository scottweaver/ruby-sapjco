require 'logging-facade'

module SapJCo
     module Configuration
          def self.configure(configuration={})

               #First test if the classpath already includes the SAPJCO API
               begin
                    require 'sapjco3.jar'
                    java_import com.sap.conn.jco.ext.Environment
                    LoggingFacade::Logger.logger.info "sapjco3.jar successfuly loaded!"
               rescue Exception => e
                    puts e
                    raise( %q{
                         The sapjco3.jar could not be located on the classpath.  Either:
                         - (easiest) Add it to you CLASSPATH environment variable.
                         - Make sure it is part of the classpath of the JVM running JRuby.
                         - (best) Create a ruby that contains the 'sapjco3.jar' in the /lib directory
                    and install the gem locally.})
               end

                LoggingFacade::Logger.logger.info ">>> Default SAPJCo destination has been set to '#{configuration[:default_destination]}' <<<" if configuration.has_key? :default_destination

               config_path = ENV['SAPJCO_CONFIG'] || 'config/sapjco.yml'
               if File.exists? config_path
                    LoggingFacade::Logger.logger.info "Configuring SAPJCo from #{File.expand_path(config_path)}."
                    @@configuration =  YAML::load(File.open(config_path))
                    @@configuration.merge!(configuration)                    
               else
                    @@configuration = configuration
                    LoggingFacade::Logger.logger.warn "No configuration file could be located so defaulting to empty configuration."
               end


               if(!Environment.destination_data_provider_registered?)
                    destination_data_provider = RubyDestinationDataProvider.new(@@configuration)
                    Environment.register_destination_data_provider(destination_data_provider)
               end
               @@configuration
          end

          def self.configuration
               @@configuration
          end

          # Create our own destination provider which converts our YAML config to a
          # java.util.Properties instance that the JCoDestinationManager can use.
          class RubyDestinationDataProvider
               include com.sap.conn.jco.ext.DestinationDataProvider,  LoggingFacade::Logger
               java_import java.util.Properties

               def initialize(configuration)
                    @destinations=configuration['destinations']
                    if(@destinations)
                      logger.info "Available SAP app server destinations: #{@destinations.keys.join(', ')}." 
                    else
                      raise "Your configuration appears to be empty or at the very least has no destinations defined."
                    end
               end

               def get_destination_properties(destination_name)
                    props = Properties.new
                    raise "Destination '#{destination_name}' is not defined in your configuration." unless @destinations.include? destination_name.to_s
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
end