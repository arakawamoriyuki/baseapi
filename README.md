# Baseapi

When you create a web application in the rails, If you want to CRUD operations in Ajax, might this gem is useful.
We only define the empty Controller and Model for us to define the CRUD in.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'baseapi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install baseapi

## Usage

Introduction create a BaseApiController & JBuilder of view:

    $ bundle exec baseapi setup

Create a Model (app/models/user.rb):

    class User < ActiveRecord::Base
    end

Extend the BaseApiController is when you create a Controller (app/controllers/users_controller.rb):

    class CompaniesController < BaseApiController
    end

Routing configuration (config/routes.rb):

    constraints(:format => /json/) do
      get     "users"       => "users#index"
      get     "users/:id"   => "users#show"
      post    "users"       => "users#create"
      patch   "users/:id"   => "users#update"
      put     "users/:id"   => "users#update"
      delete  "users/:id"   => "users#destroy"
    end

Corresponding API:

    /users.json	      index	   GET
    /users/{id}.json	show     GET
    /users.json	      create   POST
    /users/{id}.json	update   PUT
    /users/{id}.json	destroy  DELETE


### Examples

Model

    class User < ActiveRecord::Base
      belongs_to :company
    end

    class Company < ActiveRecord::Base
      has_many :users
    end

Users table data

| id | name     | company_id |
|----|----------|------------|
| 1  | hoge     | 1          |
| 2  | huga     | 2          |

Company table data

| id | name     |
|----|----------|
| 1  | Google   |
| 2  | Apple    |

#### action index

Get all

    GET   /users.json

Specify the name

    GET   /users.json?name=hoge

Specify multiple possible

    GET   /users.json?name[]=hoge&name[]=huga

Specify the belongs to company name

    GET   /users.json?company[name]=Google

Specify the has many users name

    GET   /companies.json?user[name]=hoge

#### action show

Get id 1

    GET   /users/1.json

#### action create

Create a user name is 'hoge'

    POST   /users.json?name=hoge

#### action update

Update the name to 'huga'

    PATCH  /users/1.json?name=huga
    PUT    /users/1.json?name=huga

#### action delete

Delete the id to 1

    DELETE /users/1.json

#### return json format

    {
      error: false,
      message: "",
      data: [
        {
          id: 1,
          name: "hoge"
        },
        {
          id: 2,
          name: "huga"
        }
      ]
    }

### Override

You can corresponding to the logical deletion, if you want to search condition to like and or, you will be able to override the processing in the Model


Get all

    class User < ActiveRecord::Base
      def self._all
      end
    end

delete

    class User < ActiveRecord::Base
      def _destroy
      end
    end

column search

    class User < ActiveRecord::Base
      def self._where(models, column, values)
      end
    end

name column search

    class User < ActiveRecord::Base
      def self._where_name(models, column, values)
      end
    end

belongs_to search

    class User < ActiveRecord::Base
      def self._belongs_to(models, table, hash)
      end
    end

company belongs_to search

    class User < ActiveRecord::Base
      def self._belongs_to_company(models, table, hash)
      end
    end

has_many search

    class Company < ActiveRecord::Base
      def self._has_many(models, table, hash)
      end
    end

users has_many search

    class Company < ActiveRecord::Base
      def self._has_many_users(models, table, hash)
      end
    end


There is a useful function for the associated table Search
By default, it looks like the following
'Like' search and, you can change the 'and' and 'or'

    class User < ActiveRecord::Base
      def self._belongs_to(models, table, hash)
        relation_match(models, table, hash, operator:'or') # default is match OR
        # relation_like(models, table, hash, operator:'or') # LIKE OR
        # relation_like(models, table, hash, operator:'and') # LIKE AND
      end
    end

The short so please read the [code](https://github.com/arakawamoriyuki/baseapi/blob/master/lib/baseapi/active_record/base_extension.rb) for more information

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec baseapi` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/arakawamoriyuki/baseapi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
