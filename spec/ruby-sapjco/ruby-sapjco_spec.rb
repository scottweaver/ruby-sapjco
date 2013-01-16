require_relative "../spec_helper.rb"
require 'ruby-sapjco'
require "yaml"


describe SapJCo::RubyDestinationDataProvider do

  it "should convert YAML to java.util.Properties" do
    ddp = SapJCo::RubyDestinationDataProvider.new(SapJCo::Configuration.configuration)
    props = ddp.get_destination_properties('test')
    # You should define an Expectations class in your /spec/spec_metadata to match what ever you
    # have in your /config.yml (which you also need to create)

    props.get('jco.client.ashost').should eq EXPECTATIONS[:ashost]
    props.get('jco.client.sysnr').should eq EXPECTATIONS[:sysnr]
    props.get('jco.client.client').should eq EXPECTATIONS[:client]
    props.get('jco.client.lang').should eq EXPECTATIONS[:lang]
    props.get('jco.client.user').should eq EXPECTATIONS[:user]
    props.get('jco.client.passwd').should eq EXPECTATIONS[:passwd]
  end

end


describe SapJCo::Function do

  it "should convert ugly SAPJCO Java structs into beautimous Ruby ones" do
    func =  SapJCo::Function.new(:STFC_CONNECTION)

    out = func.execute do |params|
      params[:REQUTEXT] = 'Hello SAP!'
    end

    out[:ECHOTEXT].should eq 'Hello SAP!'
  end

  it "should handle SAP structures correctly" do
    func =  SapJCo::Function.new(:RFC_SYSTEM_INFO)

    out = func.execute
    out[:RFCSI_EXPORT].should_not be nil
    out[:RFCSI_EXPORT][:RFCHOST2].should eq 'saperqapp1'
  end

  it "should handle tables correctly" do
    func =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST)

    out = func.execute
    out[:COMPANYCODE_LIST].class.should eq Array
    out[:COMPANYCODE_LIST][0][:COMP_CODE].should eq EXPECTATIONS[:company_code_0]
  end

  it "should have metadata available" do
    company_code_rfc =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST)
    sys_info_rfc =  SapJCo::Function.new(:RFC_SYSTEM_INFO)

    company_code_rfc.metadata[:function].should eq'BAPI_COMPANYCODE_GETLIST'
    company_code_rfc.metadata[:import_parameters].length.should eq 0
    company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:type].should == 'CHAR'
    company_code_rfc.metadata[:tables][:COMPANYCODE_LIST][:fields][:COMP_CODE][:description].should == 'Company Code'
    company_code_rfc.metadata[:export_parameters][:RETURN][:type].should == 'STRUCTURE'
    company_code_rfc.metadata[:export_parameters][:RETURN][:fields][:CODE][:type].should == 'CHAR'
    #company_code_rfc[:tables]
  end

  it "should create html documentation" do
    company_code_rfc =  SapJCo::Function.new(:BAPI_COMPANYCODE_GETLIST)
    company_code_rfc.help true
    install_config = SapJCo::Function.new(:Z_INSTALL_CONFIG)
    install_config.help true
  end

  it "should support failing over to an alternate server" do
    rfc =  SapJCo::Function.new(:Z_INSTALL_CONFIG)

    result = rfc.execute do |inp|
      inp[:MQUOTFLG] = "X"
      inp[:FINSTNO]='0001090130'
    end

    result.should_not be nil
    result[:TMATTAB].length.should > 0
  end
end

