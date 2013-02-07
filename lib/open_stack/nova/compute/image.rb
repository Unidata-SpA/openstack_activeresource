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

      # An OpenStack Image
      #
      # ==== Attributes
      # * +name+ - Name of this image
      # * +tenant_id+ - Tenant id to which this image belongs to (if applicable)
      # * +server_id+ - Server id to which this image belongs to (if applicable)
      # * +user_id+ - User id to which this image belongs to (if applicable)
      # * +status+ - Status of image (e.g. ACTIVE)
      # * +progress+ - Progress of image
      # * +min_disk+ - Minimal amount of storage needed by this image (GBytes)
      # * +min_ram+ - Minimal amount of RAM needed by this image (MBytes)
      # * +updated_at+ - Modification date
      # * +created_at+ - Creation date
      class Image < BaseDetail
        schema do
          attribute :name, :string
          attribute :tenant_id, :string
          attribute :server_id, :string
          attribute :user_id, :string
          attribute :status, :string
          attribute :progress, :string
          attribute :min_disk, :string
          attribute :min_ram, :string
          attribute :updated_at, :datetime
          attribute :created_at, :datetime
        end

        def initialize(attributes = {}, persisted = false) # :notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :name => attributes[:name],
              :min_ram => attributes[:minRam],
              :min_disk => attributes[:minDisk],
              :progress => attributes[:progress],
              :status => attributes[:status],
              :metadata => attributes[:metadata],
              :user_id => attributes[:user_id],
              :tenant_id => attributes[:tenant_id],
              :server_id => attributes[:server].present? ? attributes[:server][:id] : nil,
              :updated_at => attributes[:updated].present? ? DateTime.strptime(attributes[:updated], OpenStack::DATETIME_FORMAT) : nil,
              :created_at => attributes[:created].present? ? DateTime.strptime(attributes[:created], OpenStack::DATETIME_FORMAT) : nil
          }

          super(new_attributes, persisted)
        end

        # Returns the list of Image instances with the specified name
        #
        # ==== Attributes
        # * +name+ : A string
        def self.find_all_by_name(name)
          all.reject! { |image| image.name != name }
        end

        # Returns the first Image instance with the specified name
        #
        # ==== Attributes
        # * +name+ : A string
        def self.find_by_name(name)
          all.detect { |image| image.name == name }
        end

        # Returns the Server instance to which this image belongs to (if applicable)
        def server
          Server.find(server_id) if server_id.present?
        end

        # Returns the type of image: image or snapshot
        def image_type
          metadata.image_type
        rescue NoMethodError
          'image'
        end

        # True if this image is a snapshot
        def snapshot?
          image_type != 'image'
        end

      end

    end
  end
end
