# SqlcachedClient

A Ruby client for [Sqlcached](https://github.com/rmaestroni/sqlcached).

## Installation

Add this line to your application's Gemfile:

    gem 'sqlcached_client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqlcached_client

## Usage

Create your models as you would do with `ActiveRecord`.

```ruby
require 'sqlcached_client'

class Base < SqlcachedClient::Entity
  # things shared amongst all models
  server({ host: 'localhost', port: 8081 })
end


class User < Base
  entity_name 'user'

  query <<-SQL
    SELECT * FROM users WHERE id IN ({{ id }})
  SQL

  has_many :posts, where: { user_id: :id }

  has_many :pictures, class_name: 'Image',
    where: { imageable_id: :id, imageable_type: 'User' }

  has_one :address, where: { user_id: :id }
end


class Post < Base
  entity_name 'post'

  query <<-SQL
    SELECT * FROM posts WHERE author_id = {{ user_id }}
  SQL
end

```

Run some queries:
```
users = User.where(id: '1, 2, 3, 4')

users[0].pictures.each # you can navigate through the associations
```

Load in memory every associated set recursively:
```
users.build_associations # for each entity in the resultset, or...
users[0].build_associations # for a single entity
```

## Contributing

1. Fork it ( https://github.com/rmaestroni/sqlcached_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
