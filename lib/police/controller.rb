require 'police'
require 'police/errors'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/attribute'
require 'action_controller/base'

module Police
  module Controller
    def police (options = {}, &block)
      options     = {
        :user_method => :current_user,
        :user_class  => 'User'
      }.merge!(options)
      user_method = options.delete :user_method
      user_class  = options.delete :user_class

      include Police
      include InstanceMethods

      class_attribute :police_user_method, :police_user_class
      self.police_user_method = user_method
      self.police_user_class  = user_class

      hide_action :model_base_classes, :policies, :policy_class, :model_class
      helper_method :police!, :police?, :authorize!, :authorized?, :can?,
                    :cannot?, :owner?, :policy
      before_action :police!, options, &block
    end

    module InstanceMethods
      def authorize! (user, action, *models)
        if user.nil?
          user = police_user
        elsif user.is_a?(Symbol) || user.is_a?(String)
          models.unshift(action)
          user, action = police_user, user
        end
        super
      end

      def police_user
        if @police_user
          @police_user
        else
          unless (police_user = send police_user_method)
            user_class = police_user_class
            if user_class
              user_class = user_class.constantize if user_class.is_a?(String)
              police_user = user_class.new
            end
          end
          @police_user = police_user
        end
      end

      def police_user_method
        self.class.police_user_method
      end

      def police_user_class
        self.class.police_user_class
      end
    end
  end
end

ActionController::Base.send :extend, Police::Controller
