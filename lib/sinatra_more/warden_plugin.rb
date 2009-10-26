Dir.glob(File.dirname(__FILE__) + '/warden_plugin/**/*.rb').each  { |f| require f }

module SinatraMore
  module WardenPlugin
    def self.registered(app)
      app.use Warden::Manager do |manager|
        manager.default_strategies :password
        manager.failure_app = app
      end
      app.helpers SinatraMore::WardenHelpers

      # TODO Improve serializing methods
      Warden::Manager.serialize_into_session{ |user| user.nil? ? nil : user.id }
      Warden::Manager.serialize_from_session{ |id|   id.nil? ? nil : User.find(id) }

      Warden::Strategies.add(:password) do
        def valid?
          username || password
        end

        def authenticate!
          u = User.authenticate(username, password)
          u.nil? ? fail!("Could not log in") : success!(u)
        end
        
        def username
          params['username'] || params['nickname'] || params['login'] || params['email']
        end
        
        def password
          params['password'] || params['pass']
        end
      end
    end
  end
end