# ExplicitActiveRecord

If you're like a lot of Rails projects, you use `ActiveRecord`. And like a lot of other Rails projects, you probably call `save!`, `update!`, and `destroy!` on instances of your model throughout your codebase, and probably couldn't easily locate all of the places.

`ExplicitActiveRecord` exists for users of `ActiveRecord` who want to use `ActiveRecord` more explicitly.

Today, there are lots of very implicit ways to use `ActiveRecord`.

Examples:
```ruby
class MyModel < ActiveRecord::Base; end
class MyOtherModel < ActiveRecord::Base
  has_one :my_model, autosave: true
end
instance = MyModel.new

# Lots of different instance methods
instance.save!
instance.update!

# Dynamic creation methods off of associations
MyOtherModel.new.create_my_model

# Autosaves "MyModel" association
MyOtherModel.new.save!

# Can reference the class implicitly
self.class.create!

# ... and more!!!
```

This gem gives several APIs to allow you to use `ActiveRecord` more explicitly.

Note that this gem primarily exists as a way to use `ActiveRecord` explicitly when your current usage is highly implicit. We recommend eventually migrating to Ruby and Rails features once your model is using ActiveRecord explicitly. See the last section for more information.

## ExplicitActiveRecord::Persistence
`ExplicitActiveRecord::Persistence` has a single public method to find all places where persistence events — `create`, `update`, or `destroy` — happen.

Once your model is configured correctly to use `ExplicitActiveRecord::Persistence`, you will be required to wrap all code that persists your model with code that explicitly declares both the class and instance that is being persisted. See usage for more information.

### Incremental
`ExplicitActiveRecord::Persistence` is *incremental*. This means that you can include `ExplicitActiveRecord::Persistence`, and specify a *non-raising* behavior when the model is persisted implicitly, and use your logs or bug tracking system to find places where the model is implicitly raising, without breaking production. [See the `README` for `deprecation_helper` for more information on this](https://github.com/Gusto/deprecation_helper/blob/main/README.md).

### Usage 
The first step is to `include ExplicitActiveRecord::Persistence` in your models:

Secondly, you'll need to configure `dangerous_update_behaviors` (see the `deprecation_helper` gem for more info).

All together, this looks like this:
```ruby
# Example 1
class MyModel < ActiveRecord::Base
  include ExplicitActiveRecord::Persistence
  self.dangerous_update_behaviors = [DeprecationHelper::Strategies::LogError.new]
end

# Example 2
class MyOtherModel < ActiveRecord::Base
  include ExplicitActiveRecord::Persistence
  self.dangerous_update_behaviors = [DeprecationHelper::Strategies::RaiseError.new]
  has_one :my_model, autosave: true
end
```

Now you can use the `with_explicit_persistence` method to declare explicitly when the model is being persisted. Here are some examples of supported usages:

```ruby
# You can pass in a single instance of the `MyModel` class:
MyModel.with_explicit_persistence_for(instance) do
  instance.save!
end

# You can pass in multiple instances of the `MyModel` class:
MyModel.with_explicit_persistence_for([instance1, instance2]) do
  instance1.save!
  instance2.save!
end
# or
instances = [instance1, instance2]
MyModel.with_explicit_persistence_for(instances) do
  instances.destroy_all
end
```

Note that you cannot pass in a relation to `with_explicit_persistence_for` — only an instance of or array of instances of the class.

It is *not* recommended to use this dynamically, such as:
```ruby
# Don't do this!
self.class.with_explicit_persistence_forinstance) do
  instance.save!
end
```
The reason we do not want to do this is because writing to the class is no longer explicit! Just looking at this code, you cannot tell what class `self.class` is. If `self.class` is `MyModel`, then searching your codebase for `MyModel.with_explicit_persistence_for` will no longer reveal all of the persistence locations.

### Specifying different dangerous update behavior
You can specify multiple behaviors to invoke when the model is updated implicitly/dangerously, as long as that strategy conforms to `DeprecationHelper::Strategies::StrategyInterface` (see `deprecation_helper` for more information).

Note that by default, `ExplicitActiveRecord` uses the global configuration for `DeprecationHelper`. If your project has already configured `DeprecationHelper`, using:
```ruby
DeprecationHelper.configure { |config| config.deprecation_strategies = [...] })
```
then `ExplicitActiveRecord` will use the global configuration.

### How it works
When a client calls `my_model.save!` or `my_model.update!` without using the explicit persistence wrapper, `ExplicitActiveRecord::Persistence` will invoke `DeprecationHelper` with whatever deprecation strategies your model is configured with. 


## ExplicitActiveRecord::NoDbAccess 
`ExplicitActiveRecord::NoDbAccess` has a single public method to restrict the use of the database.

Once your class or module is configured correctly to use `ExplicitActiveRecord::NoDbAccess`, you will not be able to use the database within the `no_db_access` block. 

### Incremental
Note that unlike `ExplicitActiveRecord::Persistence`, `ExplicitActiveRecord::NoDbAccess` is NOT *incremental*. This means that using the DB within one of these blocks *will raise*. If you're interested in allowing `no_db_access` to behave like `Persistence`, please file an issue. It is recommended to use `NoDbAccess` in new code where you are very confident your code should not be using the DB.

### Usage 
The first step is to `include ExplicitActiveRecord::NoDbAccess` in your module or class.

Then, you can use the `no_db_access` block.

All together, this looks like this:
```ruby
class MyClass # can also be a module
  include ExplicitActiveRecord::NoDbAccess
  
  # Class method
  def self.my_method
    no_db_access do
      # anything that does not use the DB
    end
  end

  # Instance method
  def my_method
    self.class.no_db_access do
      # anything that does not use the DB
    end
  end
end
```

### How it works
`NoDbAccess` uses `ActiveSupport::Notifications` to subscribe to the `sql.active_record` event. This ensures that any DB use via `ActiveRecord` is disallowed.

# Why you want to use this gem, and why you don't

There are several native Ruby and Rails features that can be used to match the intent of this gem. `ExplicitActiveRecord` is not a total substitute for these Ruby and Rails primitives, but rather they intend to create a safe way to migrate your codebase to use them.

This gem adds some verbosity to the use of `ActiveRecord`. More importantly, Ruby offers native primitives for this sort of work. When creating a new rails project or rails engine, it is not recommended to use this gem. Instead, it is recommended to make use of `private_constant`, like this:
```ruby
module MyModule
  class MyModel < ActiveRecord::Base
  end

  private_constant :MyModel
end
```

Furthermore, I recommend not returning instances of `MyModel` when a call is made to the public API of `MyModule`. Instead, you can return a [value object](https://martinfowler.com/bliki/ValueObject.html). The important thing here is that by not returning instances of your model or letting unauthorized clients reference it, you can systematically and technically enforce the idea that your model is only persisted in one place.

Another way to implement this idea using native Rails is by using [Multiple Databases with Active Record](https://guides.rubyonrails.org/active_record_multiple_databases.html). For example, for NoDbAccess, you can simply set up a null database in your application, and switch to it within your block.

The reason this gem exists is because if your Rails project is like the ones I've seen, you are not doing this from the start. `ExplicitActiveRecord` is *not* a substitute for Ruby primitives like `private_constant` and conceptual primitives like value objects. Those primitives are the end goal, and this gem is just meant to provide a safe and incremental way to get you there.
