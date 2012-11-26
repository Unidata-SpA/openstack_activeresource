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

      class Base < OpenStack::Common

        def self.site
          if self == OpenStack::Keystone::Admin::Base
            Thread.current[:open_stack_keystone_admin_site]
          else
            super
          end
        end

        def self.site=(site)
          super(site)
          Thread.current[:open_stack_keystone_admin_site] = @site
        end

      end

    end
  end
end
