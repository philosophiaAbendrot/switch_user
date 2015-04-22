module SwitchUser
  module Provider

    class UnknownScopeError < StandardError
    end

    class Devise < Base
      def initialize(controller)
        @controller = controller
        @warden = @controller.warden
      end

      def login(user, scope = nil)
        scope = _validate_scope(scope)
        @warden.set_user(user, :scope => scope)
      end

      def logout(scope = nil)
        scope = _validate_scope(scope)
        @warden.logout(scope)
      end

      def current_user(scope = nil)
        if scope
          result = @warden.user(_validate_scope(scope))
        else
          result = (SwitchUser.available_scopes).reduce(@warden.user(scope)) do |memo, _scope|
            memo.nil? ? @warden.user(_scope) : memo
          end
        end
        result
      end

    end
  end
end
