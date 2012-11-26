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

      class Flavor < BaseDetail
        schema do
          attribute :name, :string
          attribute :ram, :integer
          attribute :disk, :integer
          attribute :vcpus, :integer
          attribute :rxtx_factor, :float
          attribute :ephemeral_disk, :integer
        end

        validates :name, :presence => true, :format => {:with => /\A[\w\.\-]+\Z/}, :length => {:minimum => 2, :maximum => 255}
        validates :ram, :presence => true, :numericality => {:greater_than_or_equal_to => 1, :only_integer => true}
        validates :vcpus, :presence => true, :numericality => {:greater_than_or_equal_to => 1, :only_integer => true}
        validates :disk, :presence => true, :numericality => {:greater_than_or_equal_to => 10, :only_integer => true}
        validates :ephemeral_disk, :presence => false, :numericality => {:greater_than_or_equal_to => 10, :only_integer => true}

        def self.find_all_by_name(name)
          all.reject! { |flavor| flavor.name != name }
        end

        def self.find_by_name(name)
          all.each { |flavor| return flavor if flavor.name == name }

          nil
        end

        def ephemeral_disk
          @attributes[:'OS-FLV-EXT-DATA:ephemeral'] || nil
        end

      end

    end
  end
end
