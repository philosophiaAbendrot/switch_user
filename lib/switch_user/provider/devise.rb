module SwitchUser
  module Provider
    class Devise < Base
      def initialize(controller)
        @controller = controller
        @warden = @controller.warden
      end

      def login(user, scope = :user)
        @warden.set_user(user, :scope => scope)
      end

      def logout(scope = :user)
        @warden.logout(scope)
      end

      def current_user(scope = nil)
        if scope
          @warden.user(scope)
        else
          result = (SwitchUser.available_scopes).reduce(@warden.user(scope)) do |memo, _scope|
            memo.nil? ? @warden.user(_scope) : memo
          end
          result
        end
      end
    end
  end
end
