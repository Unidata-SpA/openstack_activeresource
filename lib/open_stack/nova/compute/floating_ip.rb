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

      # An OpenStack Floating Ip
      #
      # ==== Attributes
      # * +ip+ - Floating IP(v4/v6) address
      # * +fixed_ip+ - Fixed IP(v4/V6) address
      # * +pool+ - The id of the pool this IP belongs to
      # * +instance_id+ - Identifier of server this IPis assigned to (if any)
      class FloatingIp < Base
        self.collection_name = "os-floating-ips"
        self.element_name = "floating_ip"

        schema do
          attribute :fixed_ip, :string
          attribute :ip, :string
          attribute :pool, :string
          attribute :instance_id, :string
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) # :nodoc: Custom encoding to deal with openstack API
          to_encode = {}
          # Optional attributes (openstack will not accept empty attribute for update/create)
          to_encode[:pool] = pool if pool.present?

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # List of addresses for a given pool
        #
        # ==== Attributes
        # * +pool+ - an instance of OpenStack::Nova::Compute::FloatingIpPool or a pool id
        def self.find_all_by_pool(pool)
          pool_id = pool.is_a?(OpenStack::Nova::Compute::FloatingIpPool) ? pool.id : pool
          all.reject! { |floating_ip| floating_ip.pool != pool_id }
        end

        # The OpenStack::Nova::Compute::Server instance this address belongs to (if any)
        def instance
          if instance_id
            @instance ||= Server.find(instance_id)
          end
        end

        # Assign the IP to a server
        #
        # ==== Attributes:
        # * +server+ - An instance of OpenStack::Nova::Compute::Server (or a server id) to assign the floating IP to
        def assign!(server)
          server_instance = server.is_a?(OpenStack::Nova::Compute::Server) ? server : Server.find(server)
          @instance = server_instance
          self.instance_id = server_instance.id

          server_instance.add_floating_ip(self)
        end
      end

    end
  end
end
