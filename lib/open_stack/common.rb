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

  class Common < Base

    # Overrides ActiveResource::Base::element_path to remove .<extension> from resources path
    def self.element_path(id, prefix_options = {}, query_options = nil)
      check_prefix_options(prefix_options)

      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    # Overrides ActiveResource::Base::collection_path to remove .<extension> from resources path
    def self.collection_path(prefix_options = {}, query_options = nil)
      check_prefix_options(prefix_options)

      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end

    # Overrides ActiveResource::CustomMethods to remove .<extension>
    def self.custom_method_collection_url(method_name, options = {})
      prefix_options, query_options = split_options(options)
      "#{prefix(prefix_options)}#{collection_name}/#{method_name}#{query_string(query_options)}"
    end

    private

    def custom_method_element_url(method_name, options = {})
      "#{self.class.prefix(prefix_options)}#{self.class.collection_name}/#{id}/#{method_name}#{self.class.__send__(:query_string, options)}"
    end

    def custom_method_new_element_url(method_name, options = {})
      "#{self.class.prefix(prefix_options)}#{self.class.collection_name}/new/#{method_name}#{self.class.__send__(:query_string, options)}"
    end

  end

end
