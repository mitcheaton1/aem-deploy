# Aem::Deploy

Simple Ruby wrapper for the docker compose cli

## Installation

You need to have the docker compose cli installed. 

Add this line to your application's Gemfile:

```ruby
gem 'aem-deploy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aem-deploy

## Usage

Intialize the object (crx host, user, and pass are required )

    $ client = Aem::Deploy.new({host: '192.168.0.1', user: 'admin', pass: 'admin'})

Install to CRX. 

    $ client.install_package('/Users/meaton/Desktop/centre.zip')

Recompile JSP's

    $ client.recompile_jsps


## Development

This project is brand new. I plan to incorporate many other methods here.
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/docker_compose_ruby.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

