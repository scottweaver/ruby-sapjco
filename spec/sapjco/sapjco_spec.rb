require File.dirname(__FILE__) + "/../spec_helper.rb"

require 'lib/sapjco'
require "yaml"
require 'ruby-debug'


expectations = Expectations.new

describe Sap::Jco do


    it "should open a connection to an SAP server" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        destination.attributes.partner_host.should eq "saperqapp1"
        destination.ping
    end

    it "should be able to call an SAP RFC" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        a_func = destination.repository.get_function('STFC_CONNECTION')
        a_func.should_not be nil
        a_func.get_import_parameter_list.set_value('REQUTEXT', 'Hello SAP!')
        a_func.execute destination
        a_func.get_export_parameter_list.get_string("ECHOTEXT").should eq 'Hello SAP!'
    end

end

describe Sap::RubyDestinationDataProvider do

    it "should convert YAML to java.util.Properties" do
        yaml_config = YAML::load(File.open(File.expand_path("../../..", __FILE__)+"/config.yml"))
        ddp = Sap::RubyDestinationDataProvider.new(yaml_config)
        props = ddp.get_destination_properties('test')
        # You should define and Expectations class in your /spec/spec_metadataer to match what ever you
        # have in your /config.yml (which you also need to create)
       
        props.get('jco.client.ashost').should eq expectations[:ashost]
        props.get('jco.client.sysnr').should eq expectations[:sysnr]
        props.get('jco.client.client').should eq expectations[:client]
        props.get('jco.client.lang').should eq expectations[:lang]
        props.get('jco.client.user').should eq expectations[:user]
        props.get('jco.client.passwd').should eq expectations[:passwd]
  
    end
    
end

describe Sap::Function do

    it "should convert ugly SAPJCO Java structs into beautimous Ruby ones" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        func =  Sap::Function.new(:STFC_CONNECTION, destination)

        out = func.execute do |params|
            params[:REQUTEXT] = 'Hello SAP!'
        end

        out[:ECHOTEXT].should eq 'Hello SAP!'
    end

    it "should handle SAP structures correctly" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        func =  Sap::Function.new(:RFC_SYSTEM_INFO, destination)

        out = func.execute 
        puts out

        out[:RFCSI_EXPORT].should_not be nil
        out[:RFCSI_EXPORT][:RFCHOST2].should eq 'saperqapp1'
    end

    it "should handle tables correctly" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        func =  Sap::Function.new(:BAPI_COMPANYCODE_GETLIST, destination)

        out = func.execute 
        puts out
        out[:COMPANYCODE_LIST].class.should eq Array
        out[:COMPANYCODE_LIST][0][:COMP_CODE].should eq expectations[:company_code_0]        
    end

    it "should have metadata available" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        company_code_rfc =  Sap::Function.new(:BAPI_COMPANYCODE_GETLIST, destination)
        sys_info_rfc =  Sap::Function.new(:RFC_SYSTEM_INFO, destination)
        p company_code_rfc.metadata.inspect
        p sys_info_rfc.metadata.inspect


        company_code_rfc.metadata[:function].should eq'BAPI_COMPANYCODE_GETLIST'
        company_code_rfc.metadata[:import_parameters].length.should eq 0
        company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:type].should == 'CHAR'
        company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:description].should == 'Company Code'
        company_code_rfc.metadata[:export_parameters][:RETURN][:type].should == 'STRUCTURE'
        company_code_rfc.metadata[:export_parameters][:RETURN][:fields][:CODE][:type].should == 'CHAR'
        #company_code_rfc[:tables]

    end

    it "should create html documentation" do
        jco = Sap::Jco.new  
        destination = jco.connect("test")
        company_code_rfc =  Sap::Function.new(:BAPI_COMPANYCODE_GETLIST, destination)
        company_code_rfc.help(true)
        #Sap::Function.new(:Z_GET_PARTNER_INVOICES, destination).help true
    end
end
