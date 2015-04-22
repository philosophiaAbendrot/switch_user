module SwitchUser
  DataSource = Struct.new(:loader, :scope, :identifier, :name) do
    def users
      loader.call.map {|u| Record.new(u, self) }
    end
    def find_by_id(id)
      obj = loader.call
      if obj < ActiveRecord::Base
        obj.find(id)
      else
        users.detect { |u| u.scope_id == "#{scope}_#{id}" }
      end
    end
  end

  GuestRecord = Struct.new(:scope) do
    def equivalent?(other_scope_id)
      scope_id == other_scope_id
    end

    def label
      "Guest"
    end

    def scope_id
    end
  end

  class GuestDataSource
    def initialize(name)
      @name = name
    end

    def users
      [ GuestRecord.new(self) ]
    end
  end

  DataSources = Struct.new(:sources) do
    def users
      sources.flat_map {|source| source.users }
    end

    def find_scope_id(scope_id)
      user = find_by_id(scope_id)
      if !user
        user = users.flat_map.detect {|u| u.scope_id == scope_id }
      end
    end

    def find_by_id(scope_id)
      match = /(.*)_(.*)/.match(scope_id)
      _scope = match[1]
      _id = match[2]
      source = sources.detect { |source| source.respond_to?(:scope) && source.scope == _scope }
      source.find_by_id(_id) if source
    end
  end

  Record = Struct.new(:user, :source) do
    def equivalent?(other_scope_id)
      scope_id == other_scope_id
    end

    def scope_id
      "#{source.scope}_#{user.send(source.identifier)}"
    end

    def label
      user.send(source.name)
    end

    def scope
      source.scope
    end
  end
end
