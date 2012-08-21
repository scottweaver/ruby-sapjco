require File.dirname(__FILE__) + "/../spec_helper.rb"

require 'ruby-sapjco'
require "yaml"
require 'ruby-debug'

SapJCo::Configuration.configure

expectations = Expectations.new

describe SapJCo::Configuration::RubyDestinationDataProvider do

    it "should convert YAML to java.util.Properties" do
        ddp = SapJCo::Configuration::RubyDestinationDataProvider.new(SapJCo::Configuration.configuration)
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

describe SapJCo::Function do

    it "should convert ugly SAPJCO Java structs into beautimous Ruby ones" do
        func =  SapJCo::Function.new(:STFC_CONNECTION, :test)

        out = func.execute do |params|
            params[:REQUTEXT] = 'Hello SAP!'
        end

        out[:ECHOTEXT].should eq 'Hello SAP!'
    end

    it "should handle SAP structures correctly" do
        func =  SapJCo::Function.new(:RFC_SYSTEM_INFO, :test)

        out = func.execute 
        out[:RFCSI_EXPORT].should_not be nil
        out[:RFCSI_EXPORT][:RFCHOST2].should eq 'saperqapp1'
    end

    it "should handle tables correctly" do
        func =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST, :test)

        out = func.execute 
        out[:COMPANYCODE_LIST].class.should eq Array
        out[:COMPANYCODE_LIST][0][:COMP_CODE].should eq expectations[:company_code_0]        
    end

    it "should have metadata available" do
        company_code_rfc =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST, :test)
        sys_info_rfc =  SapJCo::Function.new(:RFC_SYSTEM_INFO, :test)

        company_code_rfc.metadata[:function].should eq'BAPI_COMPANYCODE_GETLIST'
        company_code_rfc.metadata[:import_parameters].length.should eq 0
        company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:type].should == 'CHAR'
        company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:description].should == 'Company Code'
        company_code_rfc.metadata[:export_parameters][:RETURN][:type].should == 'STRUCTURE'
        company_code_rfc.metadata[:export_parameters][:RETURN][:fields][:CODE][:type].should == 'CHAR'
        #company_code_rfc[:tables]
    end

    it "should create html documentation" do
        company_code_rfc =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST, :test)
        company_code_rfc.help true
        install_config = SapJCo::Function.new(:Z_INSTALL_CONFIG, :test)
        install_config.help true
    end
end
