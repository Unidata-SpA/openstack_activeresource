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
      # * +name+ - The name of the flavor
      # * +ram+ - Amount of RAM (MBytes)
      # * +disk+ - Amount of storage (GBytes)
      # * +vcpus+ - Virtual CPUs
      # * +rxtx_factor+ - Traffic shaping (?)
      # * +ephemeral_disk+ - Ephemeral storage amount (GByte)
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

        # Returns a list of Flavor for a given name
        #
        # ==== Attributes
        # * +name+ - A string
        def self.find_all_by_name(name)
          all.reject { |flavor| flavor.name != name }
        end

        # Returns the first Flavor for a given name
        #
        # ==== Attributes
        # * +name+ - A string
        def self.find_by_name(name)
          all.detect { |flavor| flavor.name == name }
        end

        # Returns a list of Flavor that can be used with the given constraints
        #
        # ==== Attributes
        # * +constraints+ - Hash of constraints. Valid keys are: :ram, :vcpus, :disk
        def self.find_by_constraints(constraints = {})
          constraints = constraints.with_indifferent_access
          constraints[:ram] ||= -1.0/0.0
          constraints[:vcpus] ||= -1.0/0.0
          constraints[:disk] ||= -1.0/0.0

          all.select { |flavor| flavor.ram >= constraints[:ram] and flavor.vcpus >= constraints[:vcpus] and flavor.disk >= constraints[:disk] }
        end

        # Returns a list of Flavor that can be used with the given Image
        #
        # ==== Attributes
        # * +image+ - An OpenStack::Nova::Compute::Image instance or an Image id
        def self.applicable_for_image(image)
          image_instance = image.is_a?(OpenStack::Nova::Compute::Image) ? image : Image.find(image)

          constraints = {}
          constraints[:ram] = image.min_ram if image_instance.min_ram > 0
          constraints[:disk] = image.min_disk if image_instance.min_disk > 0

          find_by_constraints constraints
        end

        # Returns the amount of ephemeral disk
        def ephemeral_disk
          @attributes[:'OS-FLV-EXT-DATA:ephemeral'] || nil
        end

        # Returns a human-friendly description for this Flavor
        def description
          "#{vcpus} vCPU - #{ram} MB RAM - #{disk} GB Disk"
        end

      end

    end
  end
end
