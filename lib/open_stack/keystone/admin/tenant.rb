# This file is part of the OpenStack-ActiveResource
#
# Copyright (C) 2012 Unidata S.p.A. (Davide Guerri - d.guerri@unidata.it)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module OpenStack
  module Keystone
    module Admin

      # An OpenStack Tenant ("admin view")
      #
      # ==== Attributes
      # * +name+ - The name of this tenant
      # * +description+ - A description of this tenant
      # * +enabled+ - True if this tenant is enabled
      class Tenant < Base

        schema do
          attribute :enabled, :boolean
          attribute :name, :string
          attribute :description, :string
        end

        validates :enabled,
                  :presence => true,
                  :inclusion => {:in => [true, false], :allow_blank => true}
        validates :name,
                  :presence => true,
                  :format => {:with => /\A\w[\w\s]+\w\Z/, :allow_blank => true}
        validates :description,
                  :format => {:with => /\A[\w\s\.\-:@+,'"]+\Z/, :allow_blank => true}

        def initialize(params = {}, persisted = false) # :notnew:
          super(params, persisted)

          self.description = description
        end

        def self.find_every(options) # :nodoc:
          class_name = self.name.split('::').last.downcase
          begin
            case from = options[:from]
              when Symbol
                instantiate_collection(get(from, options[:params]))
              when String
                path = "#{from}#{query_string(options[:params])}"
                instantiate_collection(format.decode(connection.get(path, headers).body)[class_name.pluralize] || [])
              else
                prefix_options, query_options = split_options(options[:params])
                path = collection_path(prefix_options, query_options)
                instantiate_collection((format.decode(connection.get(path, headers).body)[class_name.pluralize] || []), prefix_options)
            end
          rescue ActiveResource::ResourceNotFound
            # Swallowing ResourceNotFound exceptions and return nil - as per
            # ActiveRecord.
            nil
          end
        end

        # List of tenant with a given name
        #
        # ==== Attributes
        # * +name+ - A string
        def self.find_by_name(name)
          all.detect { |x| x.name == name }
        end

        # List of Users (instances of OpenStack::Keystone::Admin::User) in this tenant
        #
        # ==== Attributes
        # * +scope+ - An ActiveResource scope (defaults to :all)
        def users(scope = :all)
          User.find(scope, :params => {:tenant_id => self.id})
        end

        # Returns the instance of OpenStack::Keystone::Admin::User with the given id
        #
        # ==== Attributes
        # * +id+ - A string
        def user(id)
          users(id)
        end

        # List if roles in this tenant for a given instance of OpenStack::Keystone::Admin::User or user id
        #
        # ==== Attributes
        # * +user+ - A string
        # * +scope+ - An ActiveResource scope (defaults to :all)
        def user_roles(user, scope = :all)
          user_id = user.is_a?(OpenStack::Keystone::Admin::User) ? user.id : user

          Role.find(scope, :params => {:tenant_id => self.id, :user_id => user_id})
        end

        # Adds a role to a user in this tenant
        #
        # ==== Attributes
        # * +role+ - Instance of OpenStack::Keystone::Admin::Role or a role id
        # * +user+ - Instance of OpenStack::Keystone::Admin::User or a user id
        def add_role_to_user(role, user)
          role_id = role.is_a?(OpenStack::Keystone::Admin::Role) ? role.id : role
          user_id = user.is_a?(OpenStack::Keystone::Admin::User) ? user.id : user

          put("users/#{user_id}/roles/OS-KSADM/#{role_id}", {}, "null")
        end

        # Removes a role to a user in this tenant
        #
        # ==== Attributes
        # * +role+ - Instance of OpenStack::Keystone::Admin::Role or a role id
        # * +user+ - Instance of OpenStack::Keystone::Admin::User or a user id
        def delete_role_from_user(role, user)
          role_id = role.is_a?(OpenStack::Keystone::Admin::Role) ? role.id : role
          user_id = user.is_a?(OpenStack::Keystone::Admin::User) ? user.id : user

          delete("users/#{user_id}/roles/OS-KSADM/#{role_id}")
        end

        # Returns a filtered description for this tenant
        def description=(description)
          @attributes[:description] = description.gsub /[^\w\s\.\-:@+,'"]/, '_' if description

        end
      end

    end
  end
end
