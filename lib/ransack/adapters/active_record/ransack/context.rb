require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :arel_visitor

    class << self

      def for_class(klass, options = {})
        if klass < ActiveRecord::Base
          Adapters::ActiveRecord::Context.new(klass, options)
        end
      end

      def for_object(object, options = {})
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass, options)
        end
      end

    end # << self

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @join_type = options[:join_type] || Polyamorous::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]
      @associations_pot = {}
      @lock_associations = []

      if ::ActiveRecord::VERSION::STRING >= Constants::RAILS_4_1
        @base = @join_dependency.join_root
        @engine = @base.base_klass.all.arel
      else
        @base = @join_dependency.join_base
        @engine = @base.arel_engine
      end
    end

    def bind_pair_for(key)
      @bind_pairs ||= {}

      @bind_pairs[key] ||= begin
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        [parent, attr_name] if parent && attr_name
      end
    end

    def klassify(obj)
      if Class === obj && ::ActiveRecord::Base > obj
        obj
      elsif obj.respond_to? :klass
        obj.klass
      elsif obj.respond_to? :active_record  # Rails 3
        obj.active_record
      elsif obj.respond_to? :base_klass     # Rails 4
        obj.base_klass
      else
        raise ArgumentError, "Don't know how to klassify #{obj.inspect}"
      end
    end
  end
end
