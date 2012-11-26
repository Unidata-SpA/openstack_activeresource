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

      class SimpleTenantUsage < Base
        self.element_name = "os-simple-tenant-usage"
        self.collection_name = "os-simple-tenant-usage"

        schema do
          attribute :total_hours, :float
          attribute :total_vcpus_usage, :float
          attribute :total_memory_mb_usage, :float
          attribute :total_local_gb_usage, :float
          attribute :stop, :datetime
          attribute :start, :datetime
        end

        def self.find(*arguments)
          scope = arguments.slice!(0)
          options = arguments.slice!(0) || {}

          # Add "detailed => 1" to the query_options because of broken RESTful
          # (see: http://api.openstack.org @"Simple Usage") - DG - 09/07/2012
          if options[:params].nil?
            options[:params] = {:detailed => 1}
          else
            options[:params].merge! :detailed => 1
          end

          # If there is no data for the given date intervals, an empty usage will be returned.
          # we "filter out" these entries
          case scope
            when :all then
              find_every(options).select { |su| su.attributes[:tenant_id].present? }
            when :first then
              su = find_every(options).first
              su && su.attributes[:tenant_id].present? ? su : nil
            when :last then
              su = find_every(options).last
              su && su.attributes[:tenant_id].present? ? su : nil
            when :one then
              su = find_one(options)
              su && su.attributes[:tenant_id].present? ? su : nil
            else
              su = find_single(scope, options)
              su && su.attributes[:tenant_id].present? ? su : nil
          end
        end

        def server_usages
          @attributes[:server_usages].present? ? @attributes[:server_usages] : []
        end

        def start
          DateTime.parse(@attributes[:start] + ' UTC')
        end

        def stop
          DateTime.parse(@attributes[:stop] + ' UTC')
        end

        def self.find_from_date(scope, from_date)
          now = Time.now.utc

          find(scope, :params => {
              :start => from_date.utc.strftime(OpenStack::DATETIME_FORMAT),
              :end => now.strftime(OpenStack::DATETIME_FORMAT)
          })

        end

        def self.find_between_dates(scope, from_date, to_date)
          find(scope, :params => {
              :start => from_date.utc.strftime(OpenStack::DATETIME_FORMAT),
              :end => to_date.utc.strftime(OpenStack::DATETIME_FORMAT)
          })

        end

      end

      class ServerUsage < Base

        schema do
          attribute :name, :string
          attribute :vcpus, :integer
          attribute :uptime, :integer
          attribute :hours, :float
          attribute :local_gb, :integer
          attribute :tenant_id, :string
          attribute :flavor, :string
          attribute :state, :string
          attribute :memory_mb, :integer
          attribute :started_at, :datetime
          attribute :ended_at, :datetime
        end

        def started_at
          DateTime.parse(@attributes[:started_at] + ' UTC')
        end

        def ended_at
          return nil if @attributes[:ended_at].blank?
          DateTime.parse(@attributes[:ended_at] + ' UTC')
        end

      end

    end
  end
end
