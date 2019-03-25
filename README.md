# AasmOhmPersistence

Use AASM with Ohm

## Installation

Add this line to your application's Gemfile:

    gem 'aasm_ohm_persistence'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aasm_ohm_persistence

## Usage

So far this require ohm-contrib to work

To enable AASM for Ohm:

    class MyRedisModal < Ohm::Model
      include AASM
      include AASM::Persistence::OhmPersistence

      aasm do
        # Your aasm logic
      end
    end

## Notice

Unlike active record which use instance method of class to create
callback, ohm-contrib use class method to create callbacks.

Since OhmPersistence will declare before_create inside the modal, if you
wish to include your own logic to the `before_create` callback, you need
to write it like that:

    def before_create
      super
      # your own code
    end
    
## Compatibility

Version 0.2.0 of this gem is compatible with aasm gem versions 4.3.0 - 4.9.0, except using inherited Ohm::Model 
classes with state_machine defined on superclass.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
