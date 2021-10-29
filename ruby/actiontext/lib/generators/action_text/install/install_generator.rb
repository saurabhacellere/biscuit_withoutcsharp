# frozen_string_literal: true

require "pathname"
require "json"

module ActionText
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def install_javascript_dependencies
        if defined?(Webpacker::Engine)
          rails_command "app:binstub:yarn", inline: true

          say "Installing JavaScript dependencies", :green
          yarn_command "add #{js_dependencies.map { |name, version| "#{name}@#{version}" }.join(" ")}", capture: true
        end
      end

      def append_javascript_dependencies
        if defined?(Webpacker::Engine)
          in_root do
            if (app_javascript_pack_path = Pathname.new("app/javascript/packs/application.js")).exist?
              js_dependencies.each_key do |dependency|
                line = %[require("#{dependency}")]

                unless app_javascript_pack_path.read.include? line
                  say "Adding #{dependency} to #{app_javascript_pack_path}", :green
                  append_to_file app_javascript_pack_path, "\n#{line}"
                end
              end
            else
              say <<~WARNING, :red
                WARNING: Action Text can't locate your JavaScript bundle to add its package dependencies.

                Add these lines to any bundles:

                require("trix")
                require("@rails/actiontext")

                Alternatively, install and setup the webpacker gem then rerun `bin/rails action_text:install`
                to have these dependencies added automatically.
              WARNING
            end
          end
        else
          if (application_javascript_path = Rails.root.join("app/assets/javascripts/application.js")).exist?
            insert_into_file application_javascript_path.to_s, %(\nimport "trix"\nimport "@rails/actiontext")
          else
            say <<~INSTRUCTIONS, :green
              You must import the @rails/actiontext.js and trix.js JavaScript files in your application entrypoint.
            INSTRUCTIONS
          end
        end
      end

      def create_actiontext_files
        template "actiontext.scss", "app/assets/stylesheets/actiontext.scss"

        copy_file "#{GEM_ROOT}/app/views/active_storage/blobs/_blob.html.erb",
          "app/views/active_storage/blobs/_blob.html.erb"

        copy_file "#{GEM_ROOT}/app/views/layouts/action_text/contents/_content.html.erb",
          "app/views/layouts/action_text/contents/_content.html.erb"
      end

      def enable_image_processing_gem
        if (gemfile_path = Rails.root.join("Gemfile")).exist?
          say "Ensure image_processing gem has been enabled so image uploads will work"
          uncomment_lines gemfile_path, /gem "image_processing"/
          run "bundle install"
        end
      end

      def create_migrations
        rails_command "railties:install:migrations FROM=active_storage,action_text", inline: true
      end

      hook_for :test_framework

      private
        GEM_ROOT = "#{__dir__}/../../../.."

        def js_dependencies
          js_package = JSON.load(Pathname.new("#{GEM_ROOT}/package.json"))
          js_package["peerDependencies"].merge \
            js_package["name"] => "^#{js_package["version"]}"
        end

        def yarn_command(command, config = {})
          in_root { run "#{Thor::Util.ruby_command} bin/yarn #{command}", abort_on_failure: true, **config }
        end
    end
  end
end
