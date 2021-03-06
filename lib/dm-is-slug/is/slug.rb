require 'unidecoder'
require 'dm-core'
require 'dm-core/support/chainable'
require 'dm-validations'

module DataMapper
  module Is
    module Slug
      def self.included(base)
        base.extend ClassMethods
      end

      class InvalidSlugSourceError < StandardError; end

      # @param [String] str A string to escape for use as a slug
      # @return [String] an URL-safe string
      def self.escape(str)
        s = str.to_ascii
        s.gsub!(/\W+/, ' ')
        s.strip!
        s.downcase!
        s.gsub!(/\ +/, '-')
        s
      end

      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :slug
      ##

      # Defines a +slug+ property on your model with the same length as your
      # source property. This property is Unicode escaped, and treated so as
      # to be fit for use in URLs.
      #
      # ==== Example
      # Suppose your source attribute was the following string: "Hot deals on
      # Boxing Day". This string would be escaped to "hot-deals-on-boxing-day".
      #
      # Non-ASCII characters are attempted to be converted to their nearest
      # approximate.
      #
      # ==== Parameters
      # +permanent_slug+::
      #   Permanent slugs are not changed even if the source property has
      # +source+::
      #   The property on the model to use as the source of the generated slug,
      #   or an instance method defined in the model, the method must return
      #   a string or nil.
      # +length+::
      #   The length of the +slug+ property
      #
      # @param [Hash] provide options in a Hash. See *Parameters* for details
      def is_slug(options)
        if options.key?(:size)
          warn "Slug with :size option is deprecated, use :length instead"
          options[:length] = options.delete(:size)
        end

        extend  DataMapper::Is::Slug::ClassMethods
        include DataMapper::Is::Slug::InstanceMethods
        extend Chainable

        @slug_options = {}

        @slug_options[:permanent_slug] = options.delete(:permanent_slug)
        @slug_options[:permanent_slug] = true if @slug_options[:permanent_slug].nil?

        if options.has_key? :scope
          @slug_options[:scope] = [options.delete(:scope)].flatten
        end

        @slug_options[:unique] = options.delete(:unique) || false

        @slug_options[:source] = options.delete(:source)
        raise InvalidSlugSourceError, 'You must specify a :source to generate slug.' unless slug_source


        options[:length] ||= get_slug_length
        if slug_property && slug_property.class >= DataMapper::Property::String
            options.merge! slug_property.options
        end
        property :slug, String, options

        if @slug_options[:unique]
          scope_options = @slug_options[:scope] && @slug_options[:scope].any? ?
            {:scope => @slug_options[:scope]} : {}

          validates_uniqueness_of :slug, scope_options
        end

        before :valid?, :generate_slug
      end

      module ClassMethods
        attr_reader :slug_options

        def permanent_slug?
          slug_options[:permanent_slug]
        end

        def slug_source
          slug_options[:source] ? slug_options[:source].to_sym : nil
        end

        def slug_source_property
          detect_slug_property_by_name(slug_source)
        end

        def slug_property
          detect_slug_property_by_name(:slug)
        end

        private

        def detect_slug_property_by_name(name)
          p = properties[name]
          !p.nil? && DataMapper::Property::String >= p.class ? p : nil
        end

        def get_slug_length
          slug_property.nil? ? (slug_source_property.nil? ? DataMapper::Property::String::DEFAULT_LENGTH : slug_source_property.length) : slug_property.length
        end
      end # ClassMethods

      module InstanceMethods
        def to_param
          [slug]
        end

        def permanent_slug?
          self.class.permanent_slug?
        end

        def slug_source
          self.class.slug_source
        end

        def slug_source_property
          self.class.slug_source_property
        end

        def slug_property
          self.class.slug_property
        end

        def slug_source_value
          self.send(slug_source)
        end

        # The slug is stale if
        # 1. the slug is new
        # 2. the slug is empty/has an invalid value
        # 3. a property which affects the slug is dirty
        # 4. scope change
        def stale_slug?
          stale = false
          if new?
            # slug is NEW and stale
            stale = true
          end

          if (permanent_slug? && (slug.nil? || slug.empty?)) ||
             (slug_source_value.nil? || slug_source_value.empty?)
            # Slug is empty and doesn't have a valid value
            stale = true
          end

          return true if stale == true

          if (!permanent_slug? && false == dirty_attributes.keys.map(&:name).empty?)
            # Test for staleness. Does our dirty attribute change the slug
            # source value? Lets do a test.
            dirty_attributes.keys.map(&:name).each do |key|
              prev_value = self.slug_source_value
              prev_key = self.send(key)

              # Modify the information at :key
              self.send "#{key}=", nil

              # Test the slug source value for differences. This might
              # outright fail due to us setting the property to nil, so
              # lets call it stale if that happens.
              begin
                if self.slug_source_value != prev_value
                  # slug is stale due to affected property
                  stale = true
                end
              rescue
                # slug is stale due to affected property causing exception
                stale = true
              end

              # Restore key to what it was before.
              self.send "#{key}=", prev_key

              break if stale == true

            end

          end

          return true if stale == true

          unless (dirty_attributes.keys.map(&:name) &
                      (self.class.slug_options[:scope] || [])).empty?
            # Stale due to scope change
            stale = true
          end

          stale
        end

        private

        def generate_slug
          return unless self.class.respond_to?(:slug_options) && self.class.slug_options
          raise InvalidSlugSourceError, 'Invalid slug source.' unless slug_source_property || self.respond_to?(slug_source)
          return unless stale_slug?
          attribute_set :slug, unique_slug
        end

        def unique_slug
          max_length = self.class.send(:get_slug_length)
          base_slug = ::DataMapper::Is::Slug.escape(slug_source_value)[0, max_length]
          # Assuming that 5 digits is more than enought
          index_length = 5
          new_slug = base_slug

          variations = max_length - base_slug.length - 1

          slugs = if variations > index_length + 1
            [base_slug]
          else
            ((variations - 1)..index_length).map do |n|
              base_slug[0, max_length - n - 1]
            end.uniq
          end

          not_self_conditions = {}
          unless new?
            self.model.key.each do |property|
              not_self_conditions.merge!(property.name.not => self.send(property.name))
            end
          end

          scope_conditions = {}
          if self.class.slug_options[:scope]
            self.class.slug_options[:scope].each do |subject|
              scope_conditions[subject] = self.__send__(subject)
            end
          end

          index_array = slugs.map do |s|
            # TODO: Will this break for slugs with large trailing digits which
            # shorten the "s" string due to space constraints?
            self.model.all(not_self_conditions.merge(scope_conditions).merge :slug.like => "#{s}-%")
          end.flatten.map do |r|
            index = r.slug.gsub(/^(#{slugs.join '|'})-/, '')
            index =~ /\d+/ ? index.to_i : nil
          end.compact

          max_index = index_array.max

          new_index = if index_array.empty?
            self.class.first(not_self_conditions.merge(scope_conditions).merge :slug => base_slug).nil? ? 1 : 2
          else
            if max_index > index_array.count + 1
              # Indicates we may have a sparse array.  We could reuse an index!
              # Lets find the index which can be reused.
              empty_index = nil
              index_array.sort!

              (2..index_array.max).each do |i|
                if index_array[i-2] != i
                  empty_index = i
                  break
                end
              end

              if empty_index.nil?
                max_index + 1
              else
                empty_index
              end

            else
              # Default to bumping the max index by 1 to use in our slug
              max_index + 1
            end
          end

          if new_index > 1
            slug_length = max_length - new_index.to_s.length - 1
            new_slug = "#{base_slug[0, slug_length]}-#{new_index}"
          end

          new_slug
        end
      end # InstanceMethods

      Model.send(:include, self)
    end # Slug
  end # Is
end # DataMapper
