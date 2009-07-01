module Rails
  module Generators
    class ScaffoldControllerGenerator < NamedBase
      include ControllerNamedBase

      check_class_collision :suffix => "Controller"
      class_option :orm, :desc => "ORM to generate the controller for", :banner => "NAME", :type => :string
      class_option :singleton, :type => :boolean, :desc => "Supply to create a singleton controller"

      def create_controller_files
        template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
      end

      hook_for :template_engine, :test_framework, :as => :scaffold
      invoke_if :helper

      protected

        def orm_class
          @orm_class ||= "#{options[:orm].to_s.classify}::Generators::ActionORM".constantize
        end

        def orm_instance
          @orm_instance ||= @orm_class.new(file_name)
        end
    end
  end
end