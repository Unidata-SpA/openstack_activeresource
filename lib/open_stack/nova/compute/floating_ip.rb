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

      class FloatingIp < Base
        self.collection_name = "os-floating-ips"
        self.element_name = "floating_ip"

        schema do
          attribute :fixed_ip, :string
          attribute :ip, :string
          attribute :pool, :string
          attribute :instance_id, :string
        end

        # Overload ActiveRecord::encode method
        # Custom encoding to deal with openstack API
        def encode(options={})
          to_encode = {}
          # Optional attributes (openstack will not accept empty attribute for update/create)
          to_encode[:pool] = pool if pool.present?

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        def self.find_all_by_pool(pool)
          all.reject! { |floating_ip| floating_ip.pool != pool }
        end

        def instance
          Server.find(instance_id) if instance_id
        end

        # Assign the IP to a given server
        # Params:
        # ::server:: the server to assign the floating ip to
        def assign!(server)
          server.add_floating_ip(self)
        end
      end

    end
  end
end
