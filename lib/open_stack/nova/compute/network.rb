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

      # An OpenStack Network (\*WARNING:* incomplete)
      #
      # ==== Attributes
      # * +bridge+ - Bridge name for this network
      # * +bridge_interface+ - Interface for this network
      # * +cidr+ - CIDR used by this network
      # * +label+ - Label for this network
      # * +multi_host+ - True if this network is managed by more than one controller (false otherwise)
      # * +vlan+ - Vlan ID (802.1q) used by this network
      # * +project_id+ - Tenant id associated with this network (if any)
      class Network < Base
        self.collection_name = "os-networks"

        schema do
          attribute :bridge, :string
          attribute :bridge_interface, :string
          attribute :cidr, :string
          attribute :label, :string
          attribute :multi_host, :boolean
          attribute :vlan, :integer
          attribute :project_id, :string
        end

        validates :bridge, :format => {:with => /\A[a-z][a-z0-9]{1,8}\Z/i}
        validates :bridge_interface, :format => {:with => /\A[a-z]{1,5}[a-z0-9]{1,5}(\.[0-9]{1,4})?\Z/i}
        validates :cidr, :presence => true
        validates :label, :presence => true, :format => {:with => /\A[\w\s\d]{1,20}\Z/i}
        validates :vlan, :presence => true, :numericality => {:greater_than_or_equal_to => 2, :less_than_or_equal_to => 4096}

      end

    end
  end
end
