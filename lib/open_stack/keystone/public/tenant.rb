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
    module Public

      class Tenant < Base

        schema do
          attribute :name, :string
          attribute :description, :string
          attribute :enabled, :boolean

        end

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
          self.all.each { |tenant| return tenant if tenant.name == name }
        end

        def self.find_all_by_name(name)
          self.all.reject! { |tenant| tenant.name != name }
        end

      end

    end
  end
end
