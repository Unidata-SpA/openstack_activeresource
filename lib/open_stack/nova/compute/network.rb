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
