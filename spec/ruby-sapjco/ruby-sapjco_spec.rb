require File.dirname(__FILE__) + "/../spec_helper.rb"

require 'ruby-sapjco-config'
require 'ruby-sapjco-function'
require "yaml"

SapJCo::Configuration.configure

expectations = Expectations.new

describe SapJCo::Configuration::RubyDestinationDataProvider do

    it "should convert YAML to java.util.Properties" do
        ddp = SapJCo::Configuration::RubyDestinationDataProvider.new(SapJCo::Configuration.configuration)
        props = ddp.get_destination_properties('test')
        # You should define an Expectations class in your /spec/spec_metadata to match what ever you
        # have in your /config.yml (which you also need to create)
       
        props.get('jco.client.ashost').should eq expectations[:ashost]
        props.get('jco.client.sysnr').should eq expectations[:sysnr]
        props.get('jco.client.client').should eq expectations[:client]
        props.get('jco.client.lang').should eq expectations[:lang]
        props.get('jco.client.user').should eq expectations[:user]
        props.get('jco.client.passwd').should eq expectations[:passwd]
    end
    
end


