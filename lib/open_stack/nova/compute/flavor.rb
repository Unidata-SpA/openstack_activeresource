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
      # * +swap+ - Amount of swap storage (MBytes)
      # * +vcpus+ - Virtual CPUs
      # * +rxtx_factor+ - Traffic shaping (?)
      # * +ephemeral_disk+ - Ephemeral storage amount (GByte)
      # * +is_public+ - True if the flavor is public
      class Flavor < BaseDetail

        schema do
          attribute :name, :string
          attribute :ram, :integer
          attribute :disk, :integer
          attribute :swap, :integer
          attribute :vcpus, :integer
          attribute :rxtx_factor, :float
          attribute :ephemeral_disk, :integer
          attribute :is_public, :boolean
        end

        validates :name,
                  :presence => true,
                  :format => {:with => /\A[\w\.\-]+\Z/, :allow_blank => true},
                  :length => {:minimum => 2, :maximum => 255, :allow_blank => true}
        validates :ram,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :only_integer => true, :allow_blank => true}
        validates :vcpus,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :only_integer => true, :allow_blank => true}
        validates :disk,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 10, :only_integer => true, :allow_blank => true}
        validates :swap,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :only_integer => true, :allow_blank => true}
        validates :ephemeral_disk,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 0, :only_integer => true, :allow_blank => true}
        validates :rxtx_factor,
                  :presence => true,
                  :numericality => {:only_integer => false, :allow_blank => true}
        validates :is_public,
                  :inclusion => {:in => [true, false], :allow_blank => true}

        def initialize(attributes = {}, persisted = false) # :notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :name => attributes[:name],
              :ram => attributes[:ram],
              :disk => attributes[:disk],
              :swap => attributes[:swap],
              :vcpus => attributes[:vcpus],
              :rxtx_factor => attributes[:rxtx_factor],
              :ephemeral_disk => attributes[:'OS-FLV-EXT-DATA:ephemeral'] || attributes[:ephemeral_disk],
              :is_public => attributes[:'os-flavor-access:is_public'] || attributes[:is_public]
          }
          super(new_attributes, persisted)

          self
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) # :nodoc: Custom encoding to deal with openstack API
          to_encode = {
              :flavor => {
                  :name => name,
                  :ram => ram,
                  :disk => disk,
                  :swap => swap,
                  :vcpus => vcpus
              }
          }

          # Optional attributes (openstack will not accept empty attribute for update/create)
          to_encode[:flavor][:'OS-FLV-EXT-DATA:ephemeral'] = ephemeral_disk if ephemeral_disk.present?
          to_encode[:flavor][:'os-flavor-access:is_public'] = is_public if is_public.present?
          to_encode[:flavor][:rxtx_factor] = rxtx_factor if rxtx_factor.present?

          to_encode.send("to_#{self.class.format.extension}", options)
        end

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

          self.all.select { |flavor| flavor.ram >= constraints[:ram] and flavor.vcpus >= constraints[:vcpus] and flavor.disk >= constraints[:disk] }
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

        # Returns a human-friendly description for this Flavor
        def description
          "#{vcpus} vCPU - #{ram} MB RAM - #{disk} GB Disk"
        end

      end

    end
  end
end
