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

      # A Volume attachment (this class describes an attachment of a volume to a server)
      #
      # ==== Attributes
      # * +device+ - The volume (unique) name (e.g. /dev/vdc)
      class VolumeAttachment < Base
        self.element_name = "volumeAttachment"
        self.collection_name = "os-volume_attachments"
        self.site = superclass.site + "servers/:server_id"

        schema do
          attribute :device, :string
          attribute :volume_id, :string
          attribute :server_id, :string
        end

        validates :device, :presence => true, :format => {:with => /\A[\/\\a-zA-Z0-9]+\Z/}
        validates :volume, :presence => true
        validates :server, :presence => true

        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :device => attributes[:device],
          }

          new_attachment = super(new_attributes, persisted)

          if attributes[:volume].present?
            new_attachment.volume_id = attributes[:volume].id
          else
            new_attachment.volume_id = attributes[:volumeId]
          end

          if attributes[:server].present?
            new_attachment.server_id = attributes[:server].id
          else
            new_attachment.server_id = attributes[:serverId]
          end

          new_attachment.prefix_options[:server_id] = new_attachment.server_id

          new_attachment
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) #:nodoc:
          # Custom encoding to deal with openstack API
          to_encode = {
              VolumeAttachment.element_name => {
                  :device => device,
                  :volumeId => volume_id,
                  :serverId => server_id
              }
          }
          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # Return the server to which this volume_attachment is related (if any)
        def server
          Server.find(server_id) if server_id.present?
        end

        # Bind the volume_attachment to a sever
        #
        # ==== Attributes
        # * +server+ - an OpenStack::Nova::Compute::Server instance
        def server=(server)
          @attributes[:server_id] = server.id if !persisted?
        end

        # Return the volume to which this volume_attachment is related (if any)
        def volume
          Volume::Volume.find(volume_id) if volume_id.present?
        end

        # Bind the volume_attachment to a volume
        #
        # ==== Attributes
        # * +volume+ - an OpenStack::Nova::Compute::Volume instance
        def volume=(volume)
          @attributes[:volume_id] = volume.id if !persisted?
        end

      end

    end
  end
end
