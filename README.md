# Baseapi

Restful API Controller can make simply by include the Baseapi module to your Controller.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'baseapi'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install baseapi

## Usage

Introduction create default JBuilder of view.

    $ bundle exec baseapi setup

Create a Model (app/models/user.rb)

    class User < ActiveRecord::Base
    end

include the Baseapi module to Controller (app/controlers/users_controller.rb)

    class UsersController < ApplicationController
      include BaseApi
    end

Routing configuration (config/routes.rb)

    constraints(:format => /json/) do
      resources :users, only:[:index, :show, :create, :update, :destroy]
    end

Corresponding API:

| url              | action  | method      |
|------------------|---------|-------------|
| /users.json      | index   | GET         |
| /users/{id}.json | show    | GET         |
| /users.json      | create  | POST        |
| /users/{id}.json | update  | PATCH / PUT |
| /users/{id}.json | destroy | DELETE      |


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
    SQL   =>  SELECT DISTINCT `users`.* FROM `users`

Specify the count

    GET   /users.json?count=10
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` LIMIT 10 OFFSET 0

Specify the page

    GET   /users.json?count=10&page=2
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` LIMIT 10 OFFSET 10

Specify the sorting order

    GET   /users.json?order=desc&orderby=name
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` ORDER BY `users`.`name` DESC

Specify the multiple sorting order (v0.1.22~)

    GET   /users.json?order[]=desc&order[]=asc&orderby[]=name&orderby[]=company_id
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` ORDER BY `users`.`name` DESC, `users`.`company_id` ASC

Specify the association sorting order[^1] (v0.1.23~)

    GET   /users.json?order=asc&orderby=company.name
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` ...JOIN... ORDER BY `companies`.`name` ASC

Specify the name

    GET   /users.json?name=hoge
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.name = 'hoge')

Specify multiple possible

    GET   /users.json?name[]=hoge&name[]=huga
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.name = 'hoge' or users.name = 'huga')

Specify the not id (v0.1.7~)

    GET   /users.json?id=!1
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE (NOT users.id = '1')

Of course the other is also possible (v0.1.7~)

    GET   /users.json?name=!hoge
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE (NOT users.name = 'hoge')

Specify the null name (v0.1.7~)

    GET   /users.json?name=null
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.name IS NULL)

Specify the not null name (v0.1.7~)

    GET   /users.json?name=!null
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE (NOT users.name IS NULL)

Specify the empty string and null name (v0.1.8~)

    GET   /users.json?name=empty
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.name IS NULL OR users.name = '')

Specify the not empty string and null name (v0.1.8~)

    GET   /users.json?name=!empty
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE (NOT users.name IS NULL AND NOT users.name = '')

Specify search for simply string 'empty' (v0.1.8~)

It can also be in double quotes "empty"

    GET   /users.json?name='empty'
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( workers.name = 'empty')

Specify the belongs to company name

Note that this is a single

    GET   /users.json?company[name]=Google
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` ...JOIN... WHERE ( companies.name = 'Google')

Specify the has many users name

Note that this is a multiple

    GET   /companies.json?users[name]=hoge
    SQL   =>  SELECT DISTINCT `companies`.* FROM `companies` ...JOIN... WHERE ( users.name = 'hoge')

Relationships can now specify multiple (v0.1.9~)

Specify the User belong to a development part company

    GET   /users.json?company[units][name]=development
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` ...JOIN... WHERE ( units.name = 'development')

Specify it more 20~ (v0.1.12~)

    GET   /users.json?age=>=20
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.age >= 20)

Specify the excess (v0.1.14~)

    GET   /users.json?age=>20
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.age > 20)

Specify it less ~20 (v0.1.12~)

    GET   /users.json?age=<=20
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.age <= 20)

Specify the less than (v0.1.14~)

    GET   /users.json?age=<20
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.age < 20)

Specify between 2015/09/01 ~ 2015/09/31 (v0.1.12~)

    GET   /users.json?created_at[]=>=20150901&created_at[]=<=20150931
    SQL   =>  SELECT DISTINCT `users`.* FROM `users` WHERE ( users.created_at >= 20150901 and users.created_at <= 20150931)

  Multiple conditions is "OR Search" by default

  Multiple conditions is "AND Search" and must

  provide a method such as the following to the model in advance

    class User < ActiveRecord::Base
      def self._where_created_at(models, column, values)
        column_match(models, column, values, operator:'and')
      end
    end

#### action show

Get id 1

    GET   /users/1.json
    SQL   =>  SELECT `users`.* FROM `users` WHERE `users`.`id` = 1

#### action create

Create a user name is 'hoge'

    POST   /users.json?name=hoge
    SQL   =>  INSERT INTO `example`.`users` (`id`, `name`) VALUES (NULL, 'hoge')

#### action update

Update the name to 'huga'

    PATCH  /users/1.json?name=huga
    PUT    /users/1.json?name=huga
    SQL   =>  UPDATE `example`.`users` SET `name` = 'huga' WHERE `users`.`id` = 1

#### action delete

Delete the id to 1

    DELETE /users/1.json
    SQL   =>  DELETE FROM `example`.`users` WHERE `users`.`id` = 1

#### return json format

index

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

show, create, update, destroy

    {
      error: false,
      message: "",
      data: {
        id: 1,
        name: "hoge"
      }
    }

### Module (0.1.20~)

If you want to create a View is also inclusive controller, please include a BaseApi.
index and show must be the process branches case of json request.

    class UsersController < ApplicationController

      # baseapi module
      include BaseApi

      def index
        if request.format.json?
          # json request
          return render 'models.json.jbuilder'
        else
          # html request
        end
      end

      def show
        if request.format.json?
          # json request
          return render 'model.json.jbuilder'
        else
          # html request
        end
      end

      # html request
      def new
      end

      # html request
      def edit
      end
    end

### reserved word (v0.1.13~)

We are using the following as a reserved word.

- count
- page
- order
- orderby

It can not be used as a column name in the database.

But, you can be avoided by specifying the prefix.

    class User < ActiveRecord::Base
      @reserved_word_prefix = '_'
    end

You can request as follows in doing so

    GET   /users.json?_count=10&_page=2

### Override

you will be able to override the processing in the Model.

Get all

    class User < ActiveRecord::Base
      def self._all
        self.all # default
      end
    end

delete

    class User < ActiveRecord::Base
      def _destroy
        self.destroy # default
      end
    end

column search

    class User < ActiveRecord::Base
      def self._where(models, column, values)
        column_match(models, column, values) # default
      end
    end

name column search

    class User < ActiveRecord::Base
      def self._where_name(models, column, values)
        column_match(models, column, values) # default
      end
    end

belongs_to search

    class User < ActiveRecord::Base
      def self._belongs_to(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

company belongs_to search

    class User < ActiveRecord::Base
      def self._belongs_to_company(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

If there are multiple related belongs_to (v0.1.12~)

    class User < ActiveRecord::Base
      def self._belongs_to_company_units_...(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

has_many search

    class Company < ActiveRecord::Base
      def self._has_many(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

users has_many search

    class Company < ActiveRecord::Base
      def self._has_many_users(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

If there are multiple related has_many (v0.1.12~)

    class Company < ActiveRecord::Base
      def self._has_many_users_families_...(models, table, hash)
        relation_match(models, table, hash) # default
      end
    end

### like & match, or & and Search (v0.1.3~)

There is a useful function for the table Search
By default, it looks like the following
'Like' search and, you can change the 'and' and 'or'

Simply If you want to override the search processing of the name column
column_match, you can use the column_like function.

    class User < ActiveRecord::Base
      def self._where_name(models, column, values)
        column_match(models, column, values, operator:'or') # default is match OR
        # column_like(models, column, values, operator:'or') # LIKE OR
        # column_like(models, column, values, operator:'and') # LIKE AND
      end
    end

If the search process of the related table is to override
relation_match, you can use the relation_like function.

    class User < ActiveRecord::Base
      def self._belongs_to_company(models, table, hash)
        relation_match(models, table, hash, operator:'or') # default is match OR
        # relation_like(models, table, hash, operator:'or') # LIKE OR
        # relation_like(models, table, hash, operator:'and') # LIKE AND
      end
    end

The short so please read the [code](https://github.com/arakawamoriyuki/baseapi/blob/master/lib/baseapi/active_record/base_extension.rb) for more information



### hook action (v0.1.4~)

Controller of 'create, update, destroy' function in advance by attaching the prefix of before, you can post processing.

    class CompaniesController < BaseApiController
      # Name Required items
      def before_create
        if params['name'].blank?
          raise 'Please enter your name'
        end
      end
      # delete the relation table
      def before_destroy
        User.where('company_id = ?', @model.id).each do |user|
          user.destroy()
        end
      end
    end

And if not sent the name to api in the above example, it returns an error in the json.
Message is a string that was passed to raise.

    {
      error: true,
      message: "Please enter your name",
    }


### jbuilder

create JBuilder of view (0.1.17)

    $ bundle exec baseapi setup users companies ...

Used by default [^2]

    /app/views/application/xxx.json.jbuilder # if include BaseApi
    /app/views/base_api/xxx.json.jbuilder # if extend BaseApi

but you can also make

    /app/views/{models}/xxx.json.jbuilder

It will return to a single data (action: show, create, delete, update)

    model.json.jbuilder

It will return multiple data (action: index)

    models.json.jbuilder

It will return an error content

    error.json.jbuilder

[jbuilder details here](https://github.com/rails/jbuilder)


## TODO

[^1]: orderby associated with foreign_key
[^2]: unify the default viewpath of extend and include

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec baseapi` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/arakawamoriyuki/baseapi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
