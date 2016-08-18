#encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

user_id  = Time.now.to_i
describe ActsAsLimitable::Limitable do

  it "can set configuration via Hash" do 
    lm = LimitableModel.create 

    expect(lm._limitable_thresholds).to eq( 
           {"default" => { "user" => { 1.second => 5, 1.hour => 100, 1.day => 1000}, 
                          "public_user" => { 1.second => 1, 1.hour => 25, 1.day => 100 },
                          "system" => {}},
            "extremely_restricted"=>{"user"=>{1.second=>1, 3600.seconds=>1, 1.day=>1}, 
                    "public_user"=>{1.second=>1, 3600.seconds=>1, 1.day=>1},
                      "system" => {} }
            })
  end

  it "can set configuration via method" do 
    lm = MethodConfiguredLimitedModel.create 
  end

  it "should not be able to do more than 1 extremely restricted call" do 
    user_id += 1
    user = User.create(id: user_id, name: "User_#{user_id}", role: "user") 
    lm = LimitableModel.create(user: user)
    lm.extremely_restricted
    expect{
      lm.extremely_restricted
      }.to raise_error(Exception)
  end

  it "should be able to make unlimited calls with role 'system'" do 
    user_id += 1
    user = User.create(id: user_id, name: "User_#{user_id}", role: "system") 
    lm = LimitableModel.create(user: user)
    1000.times { lm.limited1 }
    1000.times { lm.extremely_restricted }
  end

  context "Can check for different amounts of availability based on a passed block" do 
    it "will work with 1" do
      user_id += 1
      user = User.create(id: user_id, name: "User_#{user_id}", role: "user") 
      lm = LimitableModel.create(user: user)
      lm.limited_by_args_val(val: 1) 
    end

    it "will not work with 10000" do 
      user_id += 1
      user = User.create(id: user_id, name: "User_#{user_id}", role: "user") 
      lm = LimitableModel.create(user: user)
      expect {lm.limited_by_args_val(val: 10000)}.to raise_error Exception
    end
  end

end


strategies = [LimitableModel, MethodConfiguredLimitedModel]
strategies.each do |strat|
  context strat do 
    context "defined limits" do 
      before :each do 
        user_id += 1
        @user = User.create(id: user_id, name: "User_#{user_id}", role: "user") 
        user_id += 1
        @public_user = User.create(id: user_id, name: "User_#{user_id}", role: "public_user") 
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
            sleep(0.1)
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

      it "should work for static_methods" do
        begin 
          Thread.current[:user] = @public_user
          strat.static_method
        ensure
          Thread.current[:user] = nil
        end
      end

    end
  end
end
