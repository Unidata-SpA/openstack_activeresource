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

      # User Role ("admin view") (\*Warning:* incomplete)
      #
      # ==== Attributes
      # * +name+ - The name of the Role
      # * +description+ - A description of the role
      class UserRole < Base
        self.element_name = "role"
        self.site = superclass.site + "tenants/:tenant_id/users/:user_id"

        schema do
          attribute :name, :string
          attribute :description, :string
        end

        # Return the associated instance of OpenStack::Keystone::Admin::Role
        def role
          OpenStack::Keystone::Admin::Role.find(self.id) if persisted?
        end

      end

    end
  end
end
