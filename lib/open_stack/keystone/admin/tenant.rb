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

      class Tenant < Base

        schema do
          attribute :enabled, :boolean
          attribute :name, :string
          attribute :description, :string
        end

        validates :enabled, :inclusion => {:in => [true, false]}
        validates :name, :format => {:with => /\A\w[\w\s]+\w\Z/}
        validates :description, :format => {:with => /\A[\w\s\.\-:@+,'"]+\Z/}

        def self.find_every(options)
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

        def self.find_by_name(name)
          all.detect { |x| x.name == name }
        end

        def initialize(params = {}, persisted = false)
          super(params, persisted)

          self.description = description
        end


        def users(scope = :all)
          User.find(scope, :params => {:tenant_id => self.id})
        end

        def user(id)
          users(id)
        end

        def user_roles(user, scope = :all)
          Role.find(scope, :params => {:tenant_id => self.id, :user_id => user.is_a?(User) ? user.id : user})
        end

        def add_role_to_user(role, user)
          role_id = role.is_a?(OpenStack::Keystone::Admin::Role) ? role.id : role
          user_id = user.is_a?(OpenStack::Keystone::Admin::User) ? user.id : user

          put("users/#{user_id}/roles/OS-KSADM/#{role_id}", {}, "null")
        end

        def delete_role_from_user(role, user)
          role_id = role.is_a?(OpenStack::Keystone::Admin::Role) ? role.id : role
          user_id = user.is_a?(OpenStack::Keystone::Admin::User) ? user.id : user

          delete("users/#{user_id}/roles/OS-KSADM/#{role_id}")
        end

        def role(user)
          users(user)
        end

        def description=(description)
          @attributes[:description] = description.gsub /[^\w\s\.\-:@+,'"]/, '_' if description

        end
      end

    end
  end
end
