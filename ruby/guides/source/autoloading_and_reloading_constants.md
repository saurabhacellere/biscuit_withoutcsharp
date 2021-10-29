**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Autoloading and Reloading Constants
===================================

This guide documents how autoloading and reloading works in `zeitwerk` mode.

After reading this guide, you will know:

* Related Rails configuration
* Project structure
* Autoloading, reloading, and eager loading
* Single Table Inheritance
* And more

--------------------------------------------------------------------------------

Introduction
------------

INFO. This guide documents autoloading, reloading, and eager loading in Rails applications.

In a normal Ruby program, dependencies need to be loaded by hand. For example, the following controller uses classes `ApplicationController` and `Post`, and normally you'd need to put `require` calls for them:

```ruby
# DO NOT DO THIS.
require "application_controller"
require "post"
# DO NOT DO THIS.

class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

This is not the case in Rails applications, where application classes and modules are just available everywhere:

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

Idiomatic Rails applications only issue `require` calls to load stuff from their `lib` directory, the Ruby standard library, Ruby gems, etc. That is, anything that does not belong to their autoload paths, explained below.

To provide this feature, Rails manages a couple of [Zeitwerk](https://github.com/fxn/zeitwerk) loaders on your behalf.

Project Structure
-----------------

In a Rails application file names have to match the constants they define, with directories acting as namespaces.

For example, the file `app/helpers/users_helper.rb` should define `UsersHelper` and the file `app/controllers/admin/payments_controller.rb` should define `Admin::PaymentsController`.

By default, Rails configures Zeitwerk to inflect file names with `String#camelize`. For example, it expects that `app/controllers/users_controller.rb` defines the constant `UsersController` because

```ruby
"users_controller".camelize # => UsersController
```

The section _Customizing Inflections_ below documents ways to override this default.

Please, check the [Zeitwerk documentation](https://github.com/fxn/zeitwerk#file-structure) for further details.

config.autoload_paths
---------------------

We refer to the list of application directories whose contents are to be autoloaded as _autoload paths_. For example, `app/models`. Such directories represent the root namespace: `Object`.

INFO. Autoload paths are called _root directories_ in Zeitwerk documentation, but we'll stay with "autoload path" in this guide.

Within an autoload path, file names must match the constants they define as documented [here](https://github.com/fxn/zeitwerk#file-structure).

By default, the autoload paths of an application consist of all the subdirectories of `app` that exist when the application boots ---except for `assets`, `javascript`, and `views`--- plus the autoload paths of engines it might depend on.

For example, if `UsersHelper` is implemented in `app/helpers/users_helper.rb`, the module is autoloadable, you do not need (and should not write) a `require` call for it:

```bash
$ bin/rails runner 'p UsersHelper'
UsersHelper
```

Autoload paths automatically pick up any custom directories under `app`. For example, if your application has `app/presenters`, or `app/services`, etc., they are added to autoload paths.

The array of autoload paths can be extended by pushing to `config.autoload_paths`, in `config/application.rb` or `config/environments/*.rb`.

WARNING. Please do not mutate `ActiveSupport::Dependencies.autoload_paths`; the public interface to change autoload paths is `config.autoload_paths`.

These paths are managed by the `Rails.autoloaders.main` autoloader.

WARNING: The classes and modules defined in the autoload paths are reloadable. Therefore, you cannot autoload them in initializers. Please check [_Autoloading when the application boots_](#autoloading-when-the-application-boots) down below for valid ways to do that.

config.autoload_once_paths
--------------------------

Occasionally, you may want to be able to autoload classes and modules without reloading them. This is key for classes and modules that are cached somewhere.

For example, Active Job serializers are stored inside Active Job:

```ruby
# config/initializer/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

Making `MoneySerializer` reloadable would be confusing, because reloading an edited version would have no effect on that class object stored in Active Job. Indeed, if `MoneySerializer` was reloadable, starting with Rails 7 such initializer would raise a `NameError`.

Another use case are engines decorating framework classes:

```ruby
initializer "decorate ActionController::Base" do
  ActiveSupport.on_load(:action_controller_base) do
    include MyDecoration
  end
end
```

There, the module object stored in `MyDecoration` by the time the initializer runs becomes an ancestor of `ActionController::Base`, and reloading `MyDecoration` is pointless, it won't affect that ancestor chain.

The directories in `config.autoload_once_paths` are managed by `Rails.autoloaders.once` and cover those use cases by allowing you to autoload classes and modules that won't be reloaded.

The array of autoload once paths can be extended by pushing to `config.autoload_once_paths`, in `config/application.rb` or `config/environments/*.rb`. For example:

```ruby
module MyApplication
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

Classes and modules from the autoload once paths can be autoloaded in `config/initializers`. So, with that configuration this works:

```ruby
# config/initializer/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

 INFO: Technically, you can autoload classes and modules managed by the `once` autoloader in any initializer that runs after `:bootstrap_hook`.

$LOAD_PATH
----------

Autoload paths are added to `$LOAD_PATH` by default. However, Zeitwerk uses absolute file names internally, and your application should not issue `require` calls for autoloadable files, so those directories are actually not needed there. You can opt out with this flag:

```ruby
config.add_autoload_paths_to_load_path = false
```

That may speed up legitimate `require` calls a bit since there are fewer lookups. Also, if your application uses [Bootsnap](https://github.com/Shopify/bootsnap), that saves the library from building unnecessary indexes, and saves the RAM they would need.


Reloading
---------

Rails automatically reloads classes and modules if application files change.

More precisely, if the web server is running and application files have been modified, Rails unloads all autoloaded constants just before the next request is processed. That way, application classes or modules used during that request will be autoloaded again, thus picking up their current implementation in the file system.

Reloading can be enabled or disabled. The setting that controls this behavior is `config.cache_classes`, which is false by default in `development` mode (reloading enabled), and true by default in `production` mode (reloading disabled).

Rails uses an evented file monitor to detect files changes by default.  It can be configured instead to detect file changes by walking the autoload paths. This is controlled by the `config.file_watcher` setting.

In a Rails console there is no file watcher active regardless of the value of `config.cache_classes`. This is because, normally, it would be confusing to have code reloaded in the middle of a console session. Similar to an individual request, you generally want a console session to be served by a consistent, non-changing set of application classes and modules.

However, you can force a reload in the console by executing `reload!`:

```irb
irb(main):001:0> User.object_id
=> 70136277390120
irb(main):002:0> reload!
Reloading...
=> true
irb(main):003:0> User.object_id
=> 70136284426020
```

As you can see, the class object stored in the `User` constant is different after reloading.

### Reloading and Stale Objects

It is very important to understand that Ruby does not have a way to truly reload classes and modules in memory, and have that reflected everywhere they are already used. Technically, "unloading" the `User` class means removing the `User` constant via `Object.send(:remove_const, "User")`.

Therefore, code that references a reloadable class or module, but that is not executed again on reload, becomes stale. Let's see an example next.

Let's consider this initializer:

```ruby
# config/initializers/configure_payment_gateway.rb
# DO NOT DO THIS.
$PAYMENT_GATEWAY = Rails.env.production? ? RealGateway : MockedGateway
# DO NOT DO THIS.
```

The idea would be to use `$PAYMENT_GATEWAY` in the code, and let the initializer set that to the actual implementation depending on the environment.

On reload, `MockedGateway` is reloaded, but `$PAYMENT_GATEWAY` is not updated because initializers only run on boot. Therefore, it won't reflect the changes.

There are several ways to do this safely. For instance, the application could define a class method `PaymentGateway.impl` whose definition depends on the environment; or could define `PaymentGateway` to have a parent class or mixin that depends on the environment; or use the same global variable trick, but in a reloader callback, as explained below.

Let's see other situations that involve stale class or module objects.

Check out this Rails console session:

```irb
irb> joe = User.new
irb> reload!
irb> alice = User.new
irb> joe.class == alice.class
=> false
```

`joe` is an instance of the original `User` class. When there is a reload, the `User` constant then evaluates to a different, reloaded class. `alice` is an instance of the newly loaded `User`, but `joe` is not — his class is stale. You may define `joe` again, start an IRB subsession, or just launch a new console instead of calling `reload!`.

Another situation in which you may find this gotcha is subclassing reloadable classes in a place that is not reloaded:

```ruby
# lib/vip_user.rb
class VipUser < User
end
```

if `User` is reloaded, since `VipUser` is not, the superclass of `VipUser` is the original stale class object.

Bottom line: **do not cache reloadable classes or modules**.

### Autoloading when the application boots

Applications can safely autoload constants during boot using a reloader callback:

```ruby
Rails.application.reloader.to_prepare do
  $PAYMENT_GATEWAY = Rails.env.production? ? RealGateway : MockedGateway
end
```

That block runs when the application boots, and every time code is reloaded.

NOTE: For historical reasons, this callback may run twice. The code it executes must be idempotent.

However, if you do not need to reload the class, it is easier to define it in a directory which does not belong to the autoload paths. For instance, `lib` is an idiomatic choice. It does not belong to the autoload paths by default, but it does belong to `$LOAD_PATH`. Then, in the place the class is needed at boot time, just perform a regular `require` to load it.

For example, there is no point in defining reloadable Rack middleware, because changes would not be reflected in the instance stored in the middleware stack anyway. If `lib/my_app/middleware/foo.rb` defines a middleware class, then in `config/application.rb` you write:

```ruby
require "my_app/middleware/foo"
...
config.middleware.use MyApp::Middleware::Foo
```

To have changes in that middleware reflected, you need to restart the server.


Eager Loading
-------------

In production-like environments it is generally better to load all the application code when the application boots. Eager loading puts everything in memory ready to serve requests right away, and it is also [CoW](https://en.wikipedia.org/wiki/Copy-on-write)-friendly.

Eager loading is controlled by the flag `config.eager_load`, which is enabled by default in `production` mode.

The order in which files are eager-loaded is undefined.

If the `Zeitwerk` constant is defined, Rails invokes `Zeitwerk::Loader.eager_load_all` regardless of the application autoloading mode. That ensures dependencies managed by Zeitwerk are eager-loaded.


Single Table Inheritance
------------------------

Single Table Inheritance is a feature that doesn't play well with lazy loading. The reason is: its API generally needs to be able to enumerate the STI hierarchy to work correctly, whereas lazy loading defers loading classes until they are referenced. You can't enumerate what you haven't referenced yet.

In a sense, applications need to eager load STI hierarchies regardless of the loading mode.

Of course, if the application eager loads on boot, that is already accomplished. When it does not, it is in practice enough to instantiate the existing types in the database, which in development or test modes is usually fine. One way to do that is to include an STI preloading module in your `lib` directory:

```ruby
module StiPreload
  unless Rails.application.config.eager_load
    extend ActiveSupport::Concern

    included do
      cattr_accessor :preloaded, instance_accessor: false
    end

    class_methods do
      def descendants
        preload_sti unless preloaded
        super
      end

      # Constantizes all types present in the database. There might be more on
      # disk, but that does not matter in practice as far as the STI API is
      # concerned.
      #
      # Assumes store_full_sti_class is true, the default.
      def preload_sti
        types_in_db = \
          base_class.
            unscoped.
            select(inheritance_column).
            distinct.
            pluck(inheritance_column).
            compact

        types_in_db.each do |type|
          logger.debug("Preloading STI type #{type}")
          type.constantize
        end

        self.preloaded = true
      end
    end
  end
end
```

and then include it in the STI root classes of your project:

```ruby
# app/models/shape.rb
require "sti_preload"

class Shape < ApplicationRecord
  include StiPreload # Only in the root class.
end
```

```ruby
# app/models/polygon.rb
class Polygon < Shape
end
```

```ruby
# app/models/triangle.rb
class Triangle < Polygon
end
```

Customizing Inflections
-----------------------

By default, Rails uses `String#camelize` to know which constant a given file or directory name should define. For example, `posts_controller.rb` should define `PostsController` because that is what `"posts_controller".camelize` returns.

It could be the case that some particular file or directory name does not get inflected as you want. For instance, `html_parser.rb` is expected to define `HtmlParser` by default. What if you prefer the class to be `HTMLParser`? There are a few ways to customize this.

The easiest way is to define acronyms in `config/initializers/inflections.rb`:

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "HTML"
  inflect.acronym "SSL"
end
```

Doing so affects how Active Support inflects globally. That may be fine in some applications, but you can also customize how to camelize individual basenames independently from Active Support by passing a collection of overrides to the default inflectors:

```ruby
# config/initializers/zeitwerk.rb
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

That technique still depends on `String#camelize`, though, because that is what the default inflectors use as fallback. If you instead prefer not to depend on Active Support inflections at all and have absolute control over inflections, configure the inflectors to be instances of `Zeitwerk::Inflector`:

```ruby
# config/initializers/zeitwerk.rb
Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

There is no global configuration that can affect said instances; they are deterministic.

You can even define a custom inflector for full flexibility. Please check the [Zeitwerk documentation](https://github.com/fxn/zeitwerk#custom-inflector) for further details.

Autoloading and Engines
-----------------------

Engines run in the context of a parent application, and their code is autoloaded, reloaded, and eager loaded by the parent application. If the application runs in `zeitwerk` mode, the engine code is loaded by `zeitwerk` mode. If the application runs in `classic` mode, the engine code is loaded by `classic` mode.

When Rails boots, engine directories are added to the autoload paths, and from the point of view of the autoloader, there's no difference. Autoloaders' main input are the autoload paths, and whether they belong to the application source tree or to some engine source tree is irrelevant.

For example, this application uses [Devise](https://github.com/heartcombo/devise):

```
% bin/rails runner 'pp ActiveSupport::Dependencies.autoload_paths'
[".../app/controllers",
 ".../app/controllers/concerns",
 ".../app/helpers",
 ".../app/models",
 ".../app/models/concerns",
 ".../gems/devise-4.8.0/app/controllers",
 ".../gems/devise-4.8.0/app/helpers",
 ".../gems/devise-4.8.0/app/mailers"]
 ```

If the engine controls the autoloading mode of its parent application, the engine can be written as usual.

However, if an engine supports Rails 6 or Rails 6.1 and does not control its parent applications, it has to be ready to run under either `classic` or `zeitwerk` mode. Things to take into account:

1. If `classic` mode would need a `require_dependency` call to ensure some constant is loaded at some point, write it. While `zeitwerk` would not need it, it won't hurt, will just work in `zeitwerk` mode too.

2. `classic` mode underscores constant names ("User" -> "user.rb"), and `zeitwerk` mode camelizes file names ("user.rb" -> "User"). They coincide in most cases, but they don't if there are series of consecutive uppercase letters as in "HTMLParser". The easiest way to be compatible is to avoid such names. In this case, better pick "HtmlParser".

3. In `classic` mode, a file `app/model/concerns/foo.rb` is allowed to define both `Foo` and `Concerns::Foo`. In `zeitwerk` mode, there's only one option: it has to define `Foo`. In order to be compatible, define `Foo`.

Troubleshooting
---------------

The best way to follow what the loaders are doing is to inspect their activity.

The easiest way to do that is to include

```ruby
Rails.autoloaders.log!
```

in `config/application.rb` after loading the framework defaults. That will print traces to standard output.

If you prefer logging to a file, configure this instead:

```ruby
Rails.autoloaders.logger = Logger.new("#{Rails.root}/log/autoloading.log")
```

The Rails logger is not yet available when `config/application.rb` executes. If you prefer to use the Rails logger, configure this setting in an initializer instead:

```ruby
# config/initializers/log_autoloaders.rb
Rails.autoloaders.logger = Rails.logger
```

Rails.autoloaders
-----------------

The Zeitwerk instances managing your application are available at

```ruby
Rails.autoloaders.main
Rails.autoloaders.once
```

The former is the main one. The latter is there mostly for backwards compatibility reasons, in case the application has something in `config.autoload_once_paths` (this is discouraged nowadays).

The predicate

```ruby
Rails.autoloaders.zeitwerk_enabled?
```

is still available in Rails 7 applications, for compatibility with engines may want to support Rails 6.x. It just returns `true`.
