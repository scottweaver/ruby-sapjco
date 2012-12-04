require File.dirname(__FILE__) + "/../spec_helper.rb"

require 'ruby-sapjco-config'
require 'ruby-sapjco-function'
require "yaml"


describe SapJCo::Configuration::RubyDestinationDataProvider do

    it "should convert YAML to java.util.Properties" do
        ddp = SapJCo::Configuration::RubyDestinationDataProvider.new(SapJCo::Configuration.configuration)
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


