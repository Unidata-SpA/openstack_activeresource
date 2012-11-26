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
  module Nova
    module Compute

      class BaseDetail < Base

        # Overrides ActiveResource::Base::collection_path to add /details to resource path for servers and
        # to remove .<extension>
        def self.collection_path(prefix_options = {}, query_options = nil)
          check_prefix_options(prefix_options)

          prefix_options, query_options = split_options(prefix_options) if query_options.nil?
          "#{prefix(prefix_options)}#{collection_name}/detail#{query_string(query_options)}"
        end

        def self.collection_path_create(prefix_options = {}, query_options = nil)
          check_prefix_options(prefix_options)

          prefix_options, query_options = split_options(prefix_options) if query_options.nil?
          "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
        end

        def collection_path_create(options = nil)
          self.class.collection_path_create(options || prefix_options)
        end

        protected

        # Create (i.e., \save to the remote service) the \new resource.
        def create
          connection.post(collection_path_create, encode, self.class.headers).tap do |response|
            self.id = id_from_response(response)
            load_attributes_from_response(response)
          end
        end

      end

    end
  end
end

