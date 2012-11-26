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

      class KeyPair < Base
        self.collection_name = "os-keypairs"
        self.element_name = "keypair"

        schema do
          attribute :name, :string
          attribute :public_key, :string
          attribute :private_key, :string
          attribute :fingerprint, :string
        end

        def self.find_all_by_name(name)
          all.reject! { |key_pair| key_pair.name != name }
        end

        def self.find_by_name(name)
          all.each { |key_pair| return key_pair if key_pair.name == name }

          nil
        end

      end

    end
  end
end
