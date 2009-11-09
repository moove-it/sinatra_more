module SinatraMore
  module GeneratorComponents

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Performs the necessary generator for a given component choice
    # execute_component_setup(:mock, 'rr')
    def execute_component_setup(component, choice)
      return true && say("Skipping generator for #{component} component...", :yellow) if choice == 'none'
      say "Applying '#{choice}' (#{component})...", :yellow
      self.class.send(:include, generator_module_for(choice, component))
      send("setup_#{component}") if respond_to?("setup_#{component}")
    end

    # Prompts the user if necessary until a valid choice is returned for the component
    # resolve_valid_choice(:mock) => 'rr'
    def resolve_valid_choice(component)
      available_string = self.class.available_choices_for(component).join(", ")
      choice = options[component]
      until valid_choice?(component, choice)
        say("Option for --#{component} '#{choice}' is not available.", :red)
        choice = ask("Please enter a valid option for #{component} (#{available_string}):")
      end
      choice
    end

    # Returns true if the option passed is a valid choice for component
    # valid_option?(:mock, 'rr')
    def valid_choice?(component, choice)
      self.class.available_choices_for(component).include? choice.to_sym
    end

    # Returns the related module for a given component and option
    # generator_module_for('rr', :mock)
    def generator_module_for(choice, component)
      "SinatraMore::#{choice.to_s.capitalize}#{component.to_s.capitalize}Gen".constantize
    end

    # Creates a component_config file at the destination containing all component options
    # Content is a yamlized version of a hash containing component name mapping to chosen value
    def store_component_config(destination)
      create_file(destination) do
        self.class.component_types.inject({}) { |result, component|
          result[component] = options[component].to_s; result
        }.to_yaml
      end
    end

    # Loads the component config back into a hash
    # i.e retrieve_component_config(...) => { :mock => 'rr', :test => 'riot', ... }
    def retrieve_component_config(target)
      YAML.load_file(target)
    end

    # Inserts require statement into target file
    # insert_require('active_record', :path => "test/test_config.rb", :indent => 2)
    # options = { :path => '...', :indent => 2, :after => /.../ }
    def insert_require(lib, options = {})
      options.reverse_merge!(:indent => 0, :after => /require\sgem.*?\n/)
      req = "#{(' ' * options[:indent])}" << "require '#{lib}'\n"
      inject_into_file(options[:path], req, :after => options[:after])
    end

    module ClassMethods
      # Defines a class option to allow a component to be chosen and add to component type list
      # Also builds the available_choices hash of which component choices are supported
      # component_option :test, "Testing framework", :aliases => '-t', :choices => [:bacon, :shoulda]
      def component_option(name, description, options = {})
        (@available_choices ||= Hash.new({}))[name] = options[:choices]
        (@component_types ||= []) << name
        class_option name, :default => default_for(name), :aliases => options[:aliases]
      end

      # Returns the compiled list of component types which can be specified
      def component_types
        @component_types
      end

      # Returns the list of available choices for the given component (including none)
      def available_choices_for(component)
        @available_choices[component] + [:none]
      end

      # Returns the default choice for a given component
      def default_for(component)
        available_choices_for(component).first
      end
    end
  end
end
