#  ActsAsLimitable::Limitable
#
#  Useage:
#
#
#    class MyClass 
#
#      include ActsAsLimitable::Limitable 
#
#      limitable_thresholds user: { 1.hour => 500, 1.day => 2000 }
#
#      def my_method
#        ...
#      end 
#
#      limitable_methods :my_method
#
#    end
#
#
#

module ActsAsLimitable
  module Limitable
    extend ActiveSupport::Concern

    included do |base|
      base.class_attribute :_limitable_methods
      base.class_attribute :_limitable_thresholds
      base.class_attribute :_limitable_owner 
      base.class_attribute :_limitable_role 
    end

    module ClassMethods


      def limitable_thresholds thresholds
        thresholds = thresholds.with_indifferent_access if Hash === thresholds
        self._limitable_thresholds = thresholds
      end

      # Provide a lamba that will determine the Owner currently being used
      # when determining limits
      def limitable_owner &block
        self._limitable_owner = block 
      end 

      # Provide a lamba that will determine the Role currently being used
      # when determining limits
      def limitable_role &block 
        self._limitable_role = block 
      end 

      def limitable_methods *methods
        methods.each do |m| 
          __create_limited_proxies m
        end
      end 

      def limitable_method method, &block
        __create_limited_proxies method, &block
      end 

      #
      # This will actually proxy the methods
      #
      def __create_limited_proxies m, &block
        self._limitable_methods ||= {} 
        self._limitable_methods[m.to_s] = block
        # alias method to ensure limiting is enforced
        old_method = "#{m.to_s}_unlimited".to_sym 
        puts "Proxying #{self}##{m} with rate limiting"
        is_static = self.singleton_methods.include? m 
        method_definition = <<-END
        define_method :#{m} do |*args, &block|
          owner = _limitable_owner.call(self, *args)  
          role = _limitable_role.call(owner) if _limitable_role.present?
          limits = self.#{is_static ? '' : 'class.'}_get_lookup_limits role || owner
          Rails.logger.debug "ActsAsLimitable: guarding method #{m} with limits: \n\t\t\t \#{limits}"
          amount = _limitable_methods['#{m}'] rescue nil
          amount = amount.call(self, *args) if amount.present? && Proc === amount 
          amount ||= 1
          Rails.logger.debug "ActsAsLimitable: guarding #{m} unless \#{amount} are available"
          owner_id = (owner.respond_to?(:id) ? owner.id : owner.to_s) rescue "public"
          if ActsAsLimitable.check_limit_multi(self.class, owner_id, method: :#{m}, limits: limits, amount: amount)
            ActsAsLimitable.incr_bucket_vals(self.class, owner_id, method: :#{m}, limits: limits, amount: amount)
            Rails.logger.debug "ActsAsLimitable: allowed call to #{m}"
            send :#{old_method}, *args, &block
          end
        end
        END
        if is_static
          puts "Dealing with class: #{self}"
          self.class_eval("class << self; alias_method :#{old_method}, :#{m}; undef_method :#{m}; end") 
          self.class_eval("class << self; #{method_definition}; end")
        else
          alias_method old_method, m 
          undef_method m 
          eval method_definition 
        end
      end      

      # provide a scope that brings back cnt and at_time in order to configure limiting
      def init_limiting(owner, time_field: "created_at")
        at_time = Time.now.utc
        limits = _get_lookup_limits(owner)
        keys = limits.keys.clone 
        scope = self.limitable_scope(owner)
        if scope == :unlimited 
          return {}
        end
        scope = scope.order("#{time_field} DESC")
        scope = scope.where("#{time_field} > ?", Time.at(keys.max.seconds.ago))
        counts = keys.each_with_object( {} ) do |k, h|
          h[k] = 0
        end
        scope.each do |r| 
          Rails.logger.debug "ActsAsLimitable#init_limiting:  at_time[#{r.at_time}]  =>  cnt[#{r.cnt}]"
          keys.each do |duration| 
            if r.at_time > duration.seconds.ago
              Rails.logger.debug "ActsAsLimitable#init_limiting:    adding to duration[#{duration}]"
              counts[duration] += r.cnt 
            else 
              keys.delete(duration) 
            end         
          end
          break if keys.size == 0
        end
        # Clear all existing buckets
        _limitable_methods.each do |m, proc|
          ActsAsLimitable.incr_bucket_vals(self, owner.id, method: m, at_time: at_time, limits: limits, amount: -1)
          counts.each do |duration, amount|
            ActsAsLimitable.incr_bucket_val(self, owner.id, method: m, at_time: at_time, duration: duration, amount: amount)
          end
        end
        Rails.logger.debug "Loaded limits for owner[#{owner.id}] : #{counts}"
        counts
      end

      def _get_lookup_limits(role_or_owner)
        if Hash === _limitable_thresholds
          unless (String === role_or_owner) || (Symbol === role_or_owner) 
            role_or_owner = role_or_owner.role if role_or_owner.respond_to?(:role)
          end
          limits = _limitable_thresholds[role_or_owner]     
        elsif Symbol === _limitable_thresholds 
          limits = send _limitable_thresholds, role_or_owner
        end.clone
      end

    end
  end
end