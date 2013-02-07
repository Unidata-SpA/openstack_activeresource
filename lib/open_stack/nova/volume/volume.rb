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
    module Volume

      # An OpenStack Volume
      #
      # ==== Attributes
      # * +display_name+ - Volume name
      # * +display_description+ - Volume description
      # * +volume_type+ - Volume type identifier
      # * +size+ - Volume size (GBytes)
      # * +availability_zone+ - The availability zone for the volume
      # * +created_at+ - Creation date for the volume
      # * +snapshot_id+ - The snapshot id for the volume (not nil if this volume is a snapshot)
      # * +status+ - If the volume is a snapshot, this is the status of the snapshot (i.e. available)
      class Volume < Base
        schema do
          attribute :display_name, :string
          attribute :display_description, :text
          attribute :volume_type, :string
          attribute :size, :integer
          attribute :availability_zone, :string
          attribute :created_at, :datetime
          attribute :snapshot_id, :string
        end

        alias_attribute :name, :display_name

        validates :display_name, :presence => true, :format => {:with => /\A[\w\.\-]+\Z/}, :length => {:minimum => 2, :maximum => 255}
        validates :size, :presence => true, :numericality => {:greater_than_or_equal_to => 1, :only_integer => true}

        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :display_name => attributes[:display_name],
              :display_description => attributes[:display_description],
              :volume_type => attributes[:volume_type],
              :size => attributes[:size],
              :status => attributes[:status],
              :snapshot_id => attributes[:snapshot_id],
              :availability_zone => attributes[:availability_zone],
              :attachments => attributes[:attachments] || [],
              :created_at => attributes[:created].present? ? DateTime.strptime(attributes[:created], OpenStack::DATETIME_FORMAT) : nil,
          }

          super(new_attributes, persisted)
        end

        # True if the image is a snapshot
        def snapshot?
          persisted? and snapshot_id.present?
        end

        # True if the volume is attached
        def attached?
          !attachments.empty?
        end

        # The first server to which this volume is attached to (if any)
        def server
          Compute::Server.find(attachments[0].server_id) if attached?
        end

      end

    end
  end
end
