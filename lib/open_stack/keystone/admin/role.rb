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

      # An OpenStack Role ("admin view")
      #
      # ==== Attributes
      # * +name+ - The name of this role
      class Role < Base
        self.element_name = "OS-KSADM/role"

        schema do
          attribute :name, :string
        end

        validates :name,
                  :presence => true,
                  :length => {:minimum => 4, :allow_blank => true},
                  :format => {:with => /\A[0-9a-z_]+\Z/i, :allow_blank => true}

        # List Roles with a given name
        def self.find_by_name(name)
          all.detect { |role| role.name == name }
        end

      end

    end
  end
end
