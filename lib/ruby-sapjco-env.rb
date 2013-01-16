require 'java'
require 'logging-facade'

#Begin by testing to see if SAPJCo is available in the class path.
begin
  require 'sapjco3.jar'
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