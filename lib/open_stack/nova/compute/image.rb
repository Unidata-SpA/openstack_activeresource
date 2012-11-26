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

      class Image < BaseDetail
        schema do
          attribute :name, :string
          attribute :tenant_id, :string
          attribute :user_id, :string
          attribute :status, :string
          attribute :progress, :string
          attribute :min_disk, :string
          attribute :min_ram, :string
          attribute :updated_at, :datetime
          attribute :created_at, :datetime
        end

        def initialize(attributes = {}, persisted = false)
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :name => attributes[:name],
              :min_ram => attributes[:minRam],
              :min_disk => attributes[:minDisk],
              :progress => attributes[:progress],
              :status => attributes[:status],
              :metadata => attributes[:metadata],
              :server_id => attributes[:server].present? ? attributes[:server][:id] : nil,
              :updated_at => attributes[:updated].present? ? DateTime.strptime(attributes[:updated], OpenStack::DATETIME_FORMAT) : nil,
              :created_at => attributes[:created].present? ? DateTime.strptime(attributes[:created], OpenStack::DATETIME_FORMAT) : nil
          }

          super(new_attributes, persisted)
        end

        def self.find_all_by_name(name)
          all.reject! { |image| image.name != name }
        end

        def self.find_by_name(name)
          all.each { |image| return image if image.name == name }

          nil
        end

        def server
          Server.find(server_id) if server_id.present?
        end

        def image_type
          metadata.image_type
        rescue NoMethodError
          'image'
        end
      end

    end
  end
end
