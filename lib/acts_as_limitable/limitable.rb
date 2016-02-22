#
#  acts_as_limitable user: { 1.hour => 500, 1.day => 2000 }
#
#
#
#

module ActsAsLimitable
  module Limitable
    extend ActiveSupport::Concern

    module ClassMethods

      def limitable_thresholds thresholds
        class_attribute :_limitable_thresholds
        self._limitable_thresholds = thresholds.with_indifferent_access
      end

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
          puts "Proxying #{m} with rate limiting"
          undef_method m 
          define_method m do |*args, &block|
            limits = _limitable_thresholds[_limitable_role.call(self)]     
            identifiers = self.get_identifiers
            if ActsAsLimitable.check_limit_multi(identifiers, limits)
              send old_method, *args, &block
            end
          end
        end
      end      

    end

    def get_identifiers
      id
    end


  end
end