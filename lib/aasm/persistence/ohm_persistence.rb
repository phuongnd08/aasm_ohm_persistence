require "aasm/persistence/base"
require "ohm/callbacks"

module AASM
  module Persistence
    module OhmPersistence
      # This method:
      #
      # * extends the model with ClassMethods
      # * includes InstanceMethods
      #
      # Adds
      #
      #   def before_create
      #     aasm_ensure_initial_state
      #   end
      #
      # As a result, you need to call super if you are going to define before_create yourself
      #
      #   class Foo < Ohm::Model
      #     include AASM
      #     include AASM::Persistence::OhmPersistence
      #
      #     def before_create
      #       super
      #       # your code here
      #     end
      #   end
      #
      def self.included(base)
        base.send(:include, AASM::Persistence::Base)
        base.extend AASM::Persistence::OhmPersistence::ClassMethods
        base.send(:include, Ohm::Callbacks)
        base.send(:include, AASM::Persistence::OhmPersistence::InstanceMethods)
      end

      module InstanceMethods
        def before_create
          super
          aasm_ensure_initial_state
        end

        # Writes <tt>state</tt> to the state column and persists it to the database
        #
        #   foo = Foo.find(1)
        #   foo.aasm.current_state # => :opened
        #   foo.close!
        #   foo.aasm.current_state # => :closed
        #   Foo.find(1).aasm.current_state # => :closed
        #
        # NOTE: intended to be called from an event

        def aasm_write_state(state, name = :default)
          old_value = self.send(self.class.aasm(name).attribute_name)
          aasm_write_state_without_persistence(state, name)

          success = self.save

          unless success
            aasm_write_state_without_persistence(old_value, name)
            return false
          end

          true
        end

        # Writes <tt>state</tt> to the state column, but does not persist it to the database
        #
        #   foo = Foo.find(1)
        #   foo.aasm.current_state # => :opened
        #   foo.close
        #   foo.aasm.current_state # => :closed
        #   Foo.find(1).aasm.current_state # => :opened
        #   foo.save
        #   foo.aasm.current_state # => :closed
        #   Foo.find(1).aasm.current_state # => :closed
        #
        # NOTE: intended to be called from an event
        def aasm_write_state_without_persistence(state, name = :default)
          self.send(:"#{self.class.aasm(name).attribute_name}=", state.to_s)
        end

      private

        # Ensures that if the aasm_state column is nil and the record is new
        # that the initial state gets populated before validation on create
        #
        #   foo = Foo.new
        #   foo.aasm_state # => nil
        #   foo.valid?
        #   foo.aasm_state # => "open" (where :open is the initial state)
        #
        #
        #   foo = Foo.find(:first)
        #   foo.aasm_state # => 1
        #   foo.aasm_state = nil
        #   foo.valid?
        #   foo.aasm_state # => nil
        #
        def aasm_ensure_initial_state
          AASM::StateMachine[self.class].keys.each do |state_machine_name|
            next if send(self.class.aasm(state_machine_name).attribute_name).present?
            send("#{self.class.aasm(state_machine_name).attribute_name}=",
                 aasm(state_machine_name).enter_initial_state.to_s)
          end
        end
      end # InstanceMethods
    end
  end
end
