module ActsAsLimitable
  module Limitable
    extend ActiveSupport::Concern

    module ClassMethods

      def acts_as_limitable
        class_attribute :limitable_config
        self.limitable_config = {foo: "bar"}
      end

      private


    end
  end
end