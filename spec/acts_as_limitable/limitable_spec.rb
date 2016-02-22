#encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsLimitable::Limitable do

  it "can set configuration" do 
    lm = LimitableModel.create 

    expect(lm._limitable_thresholds).to eq( {"user" => { 1.second => 5, 1.hour => 100, 1.day => 1000}, 
                                          "public_user" => { 1.second => 1, 1.hour => 25, 1.day => 100 } })


  end

  context "will respect defined limits" do 
    before :each do 
      @lm = LimitableModel.create(name: "Test", role: "user")
      puts "Creating LimitableModel[#{@lm.id}] for rspec"
    end

    it "for user it should be able to send 2 per second" do    
      4.times do |x| 
        @lm.limited1
        sleep(0.6)
      end
    end

    it "for user it should NOT be able to send 6 per second" do    
      expect{
        10.times do |x| 
          @lm.limited1
          sleep(0.16)
        end
      }.to raise_error(Exception)
    end

    it "for public_user it should be able to send 1 per second" do    
      @lm.role = "public_user"
      2.times do |x| 
        @lm.limited1
        sleep(1.1)
      end
    end

    it "for public_user it should NOT be able to send 2 per second" do    
      @lm.role = "public_user"
      expect{
        4.times do |x| 
          @lm.limited1
          sleep(0.4)
        end
      }.to raise_error(Exception)
    end

  end
end