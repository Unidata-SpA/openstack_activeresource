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

# Reopens ActiveResource::Base to fix "ActiveResource nested resources not being persisted"
# See https://github.com/rails/rails/pull/3107
module ActiveResource #:nodoc:
  class Base

    def load(attributes, remove_root = false)
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      @prefix_options, attributes = split_options(attributes)

      if attributes.keys.size == 1
        remove_root = self.class.element_name == attributes.keys.first.to_s
      end

      attributes = Formats.remove_root(attributes) if remove_root

      attributes.each do |key, value|
        @attributes[key.to_s] =
            case value
              when Array
                resource = nil
                value.map do |attrs|
                  if attrs.is_a?(Hash)
                    resource ||= find_or_create_resource_for_collection(key)
                    resource.new(attrs, attrs.has_key?(resource.primary_key.to_s))
                  else
                    attrs.duplicable? ? attrs.dup : attrs
                  end
                end
              when Hash
                resource = find_or_create_resource_for(key)
                resource.new(value, value.has_key?(resource.primary_key.to_s))
              else
                value.duplicable? ? value.dup : value
            end
      end

      self
    end

  end
end