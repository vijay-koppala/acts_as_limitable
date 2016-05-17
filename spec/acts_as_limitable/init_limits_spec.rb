#encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

user_id  = Time.now.to_i - 50

strategies = [LimitableModel] #, MethodConfiguredLimitedModel]
strategies.each do |strat|
  context strat do 
    before :each do 
      user_id += 1
      @user = User.create(id: user_id, name: "User_#{user_id}", role: "user") 
      user_id += 1
      @public_user = User.create(id: user_id, name: "User_#{user_id}", role: "public_user") 
      puts "\n\nCreate user[#{@user.id}] and public_user[#{@public_user.id}]"
    end

    it "can load existing state from db" do 
      200.times do |x|
        strat.create(user: @public_user, created_at: (x * 200).seconds.ago) 
      end
      @public_user.reload
      method = strat.name.underscore.pluralize.to_sym 
      expect(@public_user.send(method).size).to eq 200
      @public_user.init_limiting
      @resource = strat.create(user: @public_user)
      expect{ @resource.limited1}.to raise_error(Exception)
    end

  end
end