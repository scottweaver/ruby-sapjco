require 'java'
require 'yaml'
require 'haml'
require 'tempfile'
require 'launchy'
require 'ruby-sapjco-config'
require 'ruby-sapjco-assist'
require 'logging-facade'

module SapJCo

    class DestinationAssistant
        include  LoggingFacade::Logger
        java_import com.sap.conn.jco.JCoDestinationManager

        def initialize(destination_name)
            @failed = false
            @destination_name = destination_name
            @original_destination = JCoDestinationManager.get_destination @destination_name.to_s
            @active_destination = @original_destination
        end

        def destination
            begin
                if @failed
                    attempt_reconnection
                else
                    @active_destination.ping
                    @failed = false
                end
                @active_destination
            rescue Exception => e
                logger.error "Failed to connect to destination. #{e.message} "
                failover_if_applicable(e)
            end

        end

        def failover_if_applicable(e)
            error_keys = %w{JCO_ERROR_LOGON_FAILURE JCO_ERROR_COMMUNICATION}
            @fo_destination_name ||= Configuration.configuration['destinations'][@destination_name.to_s]['failover']
            @fo_destination ||= JCoDestinationManager.get_destination(@fo_destination_name) if @fo_destination_name
            if @fo_destination && (e.respond_to?(:key) && error_keys.include?(e.key))
                logger.warn "Switching to failover destination #{@fo_destination_name}:
                \n#{@fo_destination.attributes}"
                fo_config = Configuration.configuration['destinations'][@fo_destination_name]
                @retry_after_failing = fo_config[:retry_after_failing] || 60
                @retry_at = Time.now + @retry_after_failing
                logger.info "Will attempt to switch back to '#{@destination_name}' in #{@retry_after_failing} seconds."
                logger.info "Next attempt to reach destination '#{@destination_name}' at or after #{@retry_at}."
                @active_destination = @fo_destination
                @failed=true
            else
                @active_destination = @original_destination
            end
            @active_destination
        end

        def attempt_reconnection
            if @fo_destination && Time.now > @retry_at
                logger.info "Attempting to restablish connection to original destination '#{@destination.name}'."
                begin
                    @destination.ping
                    logger.info "'#{@destination.name}' appears to be availble, reconnecting to:\n#{@destination.attributes}."
                    @active_destination = @original_destination
                    @failed = false
                rescue Exception => e
                    @retry_at = Time.now
                    logger.warn "'#{@destination.name}' still appears to be unavailable, will retry again at #{@retry_at}.  Error: #{e}"
                end
            end
            @active_destination
        end

        def reset
            @active_destination = @original_destination
        end

        def failover
            @active_destination = @fo_destination
        end

    end
end