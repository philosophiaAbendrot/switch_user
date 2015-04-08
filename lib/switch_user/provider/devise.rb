module SwitchUser
  module Provider
    class Devise < Base
      def initialize(controller)
        @controller = controller
        @warden = @controller.warden
      end

      def login(user, scope = :user)
        @warden.session_serializer.store(user, scope)
      end

      def logout(scope = :user)
        @warden.logout(scope)
      end

      def current_user(scope = :user)
        result = (SwitchUser.available_scopes).reduce(@warden.user(scope)) do |memo, _scope|
          memo.nil? ? @warden.user(_scope) : memo
        end
        result
      end
    end
  end
end
