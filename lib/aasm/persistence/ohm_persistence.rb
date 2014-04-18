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

      module ClassMethods
        def find_in_state(id, state, *args)
          find(aasm_column.to_sym => state)[id]
        end

        def count_in_state(state, *args)
          find(aasm_column.to_sym => state).count
        end
      end

      module InstanceMethods
        def before_create
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

        def aasm_write_state(state)
          old_value = self.send(self.class.aasm_column.to_sym)
          aasm_write_state_without_persistence(state)

          success = self.save

          unless success
            aasm_write_state_without_persistence(old_value)
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
        def aasm_write_state_without_persistence(state)
          self.send(:"#{self.class.aasm_column}=", state.to_s)
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
          aasm.enter_initial_state if send(self.class.aasm_column).blank?
        end
      end # InstanceMethods
    end
  end
end

