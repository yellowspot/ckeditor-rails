require 'ckeditor-rails/asset_url_processor'

module Ckeditor
  module Rails
    class Engine < ::Rails::Engine
      initializer 'ckeditor.assets.precompile', group: :all do |app|
        app.config.assets.precompile += Ckeditor::Rails::Asset.new.files
      end

      # Follow sprockets-rails 3.3.0+ to use postprocessor of Sprockets
      # https://github.com/rails/sprockets-rails/blob/v3.3.0/lib/sprockets/railtie.rb#L121
      #
      # This must be registered *before* sprockets-rails' own
      # :asset_url_processor so that it runs first over the data. Sprockets
      # registers postprocessors with `unshift` and applies them in reverse, so
      # whichever processor is registered last is the one that sees the
      # original, unmodified `url()`.
      #
      # The order matters because of how the two processors cooperate:
      # sprockets-rails tries to resolve `icons.png` through the asset pipeline,
      # fails (the gem vendors images under vendor/assets/images/ckeditor and
      # stylesheets under vendor/assets/stylesheets/ckeditor, and Sprockets 4
      # only resolves relative urls against the file's own directory), and emits
      # the fallback `/icons.png`. This processor then recognises that bare path
      # and relocates it into its own tree.
      #
      # Running second instead means receiving an already absolute url as soon
      # as config.asset_host is set, which REGEX below deliberately skips, so
      # every reference in CKEditor's stylesheets is left unresolved.
      initializer 'ckeditor.asset_url_processor', before: :asset_url_processor do |app|
        # Processors of Sprockets 2.x should inherit from Tilt::Template
        # Processors of Sprockets 3+ should respond to :call
        if Gem::Version.new(::Sprockets::VERSION) > Gem::Version.new('3')
          ::Sprockets.register_postprocessor 'text/css', ::Ckeditor::Rails::AssetUrlProcessor
        end
      end

      rake_tasks do
        load "ckeditor-rails/tasks.rake"
      end
    end
  end
end
