require 'java'
require 'logging-facade'

#First, we will see if the sapjco3.jar is in the $LOAD_PATH
begin
  require 'sapjco3.jar'  
  LoggingFacade::Logger.info "sapjco3.jar was successfuly found on the LOAD_PATH"
rescue LoadError => e
  LoggingFacade::Logger.logger.info "sapjco3.jar was not on the LOAD_PATH.  
  You can ignore this message if you have added sapcjo3.jar into the classpath
  already through some other means."
end

#Begin by testing to see if SAPJCo is available in the class path.
begin  
  java_import com.sap.conn.jco.ext.Environment
  java_import Java::ComSapConnJcoRt::DefaultListMetaData
  java_import Java::ComSapConnJcoRt::DefaultRecordMetaData
  LoggingFacade::Logger.logger.info "sapjco3.jar successfuly loaded!"
rescue Exception => e
  puts e
  raise( %q{
           The sapjco3.jar could not be located on the classpath.  Either:
           - Add it to you CLASSPATH environment variable.
           - Make sure it is part of the classpath of the JVM running JRuby.
           - Create a ruby that contains the 'sapjco3.jar' in the /lib directory
  and install the gem locally.})
end