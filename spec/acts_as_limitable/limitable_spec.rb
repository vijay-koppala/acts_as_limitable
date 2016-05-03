#encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsLimitable::Limitable do

  it "can set configuration via Hash" do 
    lm = LimitableModel.create 

    expect(lm._limitable_thresholds).to eq( {"user" => { 1.second => 5, 1.hour => 100, 1.day => 1000}, 
                                          "public_user" => { 1.second => 1, 1.hour => 25, 1.day => 100 } })
  end

  it "can set configuration via method" do 
    lm = MethodConfiguredLimitedModel.create 

  end
end

strategies = [LimitableModel, MethodConfiguredLimitedModel]
strategies.each do |strat|
  context strat do 
    context "defined limits" do 
      before :each do 
        @user = User.create(name: "User_#{Time.now.to_i}", role: "user") 
        @public_user = User.create(name: "User_#{Time.now.to_i}", role: "public_user") 
        puts "\n\nCreate user[#{@user.id}] and public_user[#{@public_user.id}]"
      end

      it "for user it should be able to send 2 per second" do    
        @resource = strat.create(user: @user)
        4.times do |x| 
          @resource.limited1
          sleep(0.6)
        end
      end

      it "for user it should NOT be able to send > 5 per second" do    
        @resource = strat.create(user: @user)
        expect{
          10.times do |x| 
            @resource.limited1
            sleep(0.13)
          end
        }.to raise_error(Exception)
      end

      it "for public_user it should be able to send 1 per second" do    
        @resource = strat.create(user: @public_user)
        2.times do |x| 
          @resource.limited1
          sleep(1.1)
        end
      end

      it "for public_user it should NOT be able to send > 1 per second" do    
        @resource = strat.create(user: @public_user)
        expect{
          5.times do |x|             
            @resource.limited1
            sleep(0.35)
          end
        }.to raise_error(Exception)
      end

      it "can load existing state from db" do 
        100.times do |x|
          strat.create(user: @user, created_at: (x * 20).seconds.ago) 
        end
        @user.reload
        method = strat.name.underscore.pluralize.to_sym 
        expect(@user.send(method).size).to eq 100
        @user.init_limiting 
      end

    end
  end
end
