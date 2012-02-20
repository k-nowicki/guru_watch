# -*- coding: UTF-8 -*-

module Backends

  module Memory

    class Gateway < Abstract::Gateway

      def first( query )
        all( query ).first  # could be optimized if necessary
      end

      def all( query )
        objects = root[query.options.entities_name] || []
        objects = all_where( query, objects )
        objects = all_where_not( query, objects )
        objects
        #deep_copy( objects )
      end

      def save_without_validation( external_object )
        object = deep_copy( external_object )
        plural = get_plural( object )
        objects = ( root[plural] ||= [] )
        if external_object.id.nil?
          id = new_id( objects )
          object.id = id
          external_object.id = id
        end
        objects << object
        nil
      end

      def save( external_object )
        if external_object.valid?
          save_without_validation( external_object )
          true
        else
          false
        end
      end

      def save!( object )
        if object.valid?
          save_without_validation( object )
          return true
        else
          raise ObjectInvalid.new( object.errors.inspect )
        end
      end

      def find( query, id )
        query.where( :id => id ).first  ||  raise( ObjectNotFound.new( "#{query.options.entities_name}/#{id} not found" ) )
      end

      private

        def new_id( existing_objects )
          begin
            rand_id = rand( 2**31 )
          end while existing_objects.map( &:id ).include?( rand_id )

          return rand_id
        end

        def get_plural( object )
          object.class.name.demodulize.tableize.to_sym
        end

        def first_where( query, objects )
          conditions = query.options.where
          return objects.first unless conditions
          objects.find { |object| object_meets_conditions?( object, conditions ) }
        end

        def all_where( query, objects )
          conditions = query.options.where
          return objects unless conditions
          objects.select { |object| object_meets_conditions?( object, conditions ) }
        end

        def all_where_not( query, objects )
          conditions = query.options.where_not
          return objects unless conditions
          objects.select { |object| !object_meets_conditions?( object, conditions ) }
        end

        def object_meets_conditions?( object, conditions )
          conditions.all? { |attr, value|
            object.send( attr ) == value
          }
        end

        def root
          backend.root
        end

        def deep_copy( object )
          backend.deep_copy( object )
        end
    end

  end

end