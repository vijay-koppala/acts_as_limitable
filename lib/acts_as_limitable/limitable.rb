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

    module ClassMethods

      def limitable_thresholds thresholds
        class_attribute :_limitable_thresholds
        thresholds = thresholds.with_indifferent_access if Hash === thresholds
        self._limitable_thresholds = thresholds
      end

      # Provide a lamba that will determine the Owner currently being used
      # when determining limits
      def limitable_owner lambda_owner 
        class_attribute :_limitable_owner 
        self._limitable_owner = lambda_owner 
      end 

      # Provide a lamba that will determine the Role currently being used
      # when determining limits
      def limitable_role lambda_role 
        class_attribute :_limitable_role 
        self._limitable_role = lambda_role 
      end 

      def limitable_methods *methods
        class_attribute :_limitable_methods
        self._limitable_methods = methods 
        __create_limited_proxies
      end 

      def __create_limited_proxies      
        _limitable_methods.each do |m| 
          # alias each method to ensure limiting is enforced
          old_method = "#{m.to_s}_unlimited".to_sym 
          alias_method old_method, m 
          puts "Proxying #{self}##{m} with rate limiting"
          undef_method m 
          define_method m do |*args, &block|
            owner = _limitable_owner.call(self)
            role = _limitable_role.call(owner) if defined?(_limitable_role)
            limits = self.class._get_lookup_limits role || owner
            identifiers = self._get_limit_identifier
            if ActsAsLimitable.check_limit_multi(self.class, identifiers, method: m, limits: limits)
              # puts "ActsAsLimitable: Calling original method: #{self.class}##{m}"
              ActsAsLimitable.incr_bucket_vals(self.class, identifiers, method: m, limits: limits, amount: 1)
              send old_method, *args, &block
            end
          end
        end
      end      

      # provide a scope that brings back cnt and at_time in order to configure limiting
      def init_limiting(owner)
        limits = _get_lookup_limits(owner)
        keys = limits.keys.clone 
        scope = self.limitable_scope(owner)
        scope.order("at_time DESC")
        scope.where("at_time > ?", Time.at(keys.max.seconds.ago))
        counts = keys.each_with_object( {} ) do |k, h|
          h[k] = 0
        end

        scope.each do |r| 
          keys.each do |duration| 
            if r.at_time > duration.seconds.ago
              counts[duration] += r.cnt 
            else 
              keys.delete(duration) 
            end         
          end
          break if keys.size == 0
        end
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

    def _get_limit_identifier
      user_id
    end



  end
end