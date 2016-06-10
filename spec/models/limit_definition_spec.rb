# create_table :limit_definitions do |t|
#   t.string :role, :limit => 50, :default => "default"   # lite, pro, etc...
#   t.string :interval_expression, :limit => 50           # "1.week", "1.day", etc...
#   t.integer :interval_seconds                           # number of seconds in interval_expression
#   t.integer :allowance                                  # how many calls are allowed during this interval 
#   t.timestamps
#
# 
#

require File.expand_path('../../spec_helper', __FILE__)

def mld(aspect, role, expr, amt)
  LimitDefinition.create( aspect: aspect,
                            role: role, 
             interval_expression: expr, 
                       allowance: amt)  
end

describe LimitDefinition, type: :model do 


  it "can be created" do 
    ld = mld("test", "pro", "5.days", 500)
    expect(ld.role).to eq "pro"
    expect(ld.interval_seconds).to eq 432000  # 5.days.to_i
    expect(ld.allowance).to eq 500
  end

  it "can return a hash of limits for a given aspect(test) and role(pro)" do 
    mld("test", "pro", "1.day", 500)
    mld("test", "pro", "1.week", 2500)
    mld("test", "pro", "1.month", 10000)
    limits = LimitDefinition.for_role("test", "pro")
    expect(limits).to eq({86400=>500, 604800=>2500, 2592000=>10000})
  end

  it "can handle configurations of multiple aspects(test1,test2) and roles(lite,pro)" do 
    limits = [
      [["1.day", 100],["1.week", 300]],
      [["1.day", 200],["1.week", 500]],
      [["1.day", 300],["1.week", 800]],
      [["1.day", 500],["1.week", 900]],
    ]
    idx = 0
    %w(test1 test2).each do |aspect|
      %w(lite pro).each do |role| 
        limits[idx].each do |limit|
          mld(aspect, role, limit[0], limit[1])
        end
        expect(LimitDefinition.for_role(aspect,role)).to eq({eval(limits[idx][0][0]).to_i => limits[idx][0][1], 
                                                              eval(limits[idx][1][0]).to_i => limits[idx][1][1] })
        idx += 1
      end
    end

    expect(LimitDefinition.limits_config("test1")).to eq({ "lite"=>{86400=>100, 604800=>300}, 
                                                            "pro"=>{86400=>200, 604800=>500}})
    expect(LimitDefinition.limits_config("test2")).to eq({ "lite"=>{86400=>300, 604800=>800}, 
                                                            "pro"=>{86400=>500, 604800=>900}})
  end

  it "can enforce limits based on LimitDefinition records" do 
    config = {
           public_user: { 1.second.to_i => 1, 1.hour.to_i => 25, 1.day.to_i => 100 },
                  user: { 1.second.to_i => 5, 1.hour.to_i => 100, 1.day.to_i => 1000}
    }
    LimitDefinition.create_limits( "test", config: config)
    expect(LimitDefinition.limits_config("test")).to eq config.with_indifferent_access

  end

  context "will maintain ActiveSupport::Duration syntax" do 
    # although hours and weeks are sometimes turned into seconds and weeks, the
    # resulting expression should be another ActiveSupport::Duration
    types = %w(second hour day week month seconds hours days weeks months)
  
    types.each_with_index do |type,idx|
      it "can handle #{type}" do 
        LimitDefinition.create_limits("test", config: {user: { (2.send(type)) => 2 }} )
        expect(types.include?(LimitDefinition.first.interval_expression.split.last)).not_to be_nil
        expect(LimitDefinition.first.interval_seconds).to eq (2.send(type).to_i)
      end
    end
  end


end