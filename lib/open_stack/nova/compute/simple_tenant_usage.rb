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

      # Server usages for a tenant
      #
      # ==== Attributes
      # * +total_hours+ - Amount of hour the SimpleTenantUsage instance is related to
      # * +total_vcpus_usage+ - Aggregated virtual cpu usage
      # * +total_memory_mb_usage+ - Aggregated memory usage (MBytes)
      # * +total_local_gb_usage+ - Aggregated storage usage (GBytes)
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

        # Redefine the find method to add the detailed flag
        def self.find(*arguments) # :nodoc:
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

        # Find all server usage from a given date to the current one
        #
        # ==== Attributes
        # * +scope+ - ActiveResource scope (:all, :first, :last, :one or an id)
        # * +from_date+ - Initial date
        def self.find_from_date(scope, from_date)
          now = Time.now.utc

          find(scope, :params => {
              :start => from_date.utc.strftime(OpenStack::DATETIME_FORMAT),
              :end => now.strftime(OpenStack::DATETIME_FORMAT)
          })

        end

        # Find all server usage between the given dates
        #
        # ==== Attributes
        # * +scope+ - ActiveResource scope (:all, :first, :last, :one or an id)
        # * +from_date+ - Initial date
        # * +to_date+ - Final date
        def self.find_between_dates(scope, from_date, to_date)
          find(scope, :params => {
              :start => from_date.utc.strftime(OpenStack::DATETIME_FORMAT),
              :end => to_date.utc.strftime(OpenStack::DATETIME_FORMAT)
          })

        end

        # OpenStack::Nova::Compute::ServerUsage instances
        def server_usages
          @attributes[:server_usages].present? ? @attributes[:server_usages] : []
        end

        # The start date for the ServerUsage set
        def start
          DateTime.parse(@attributes[:start] + ' UTC')
        end

        # The stop date for the ServerUsage set
        def stop
          DateTime.parse(@attributes[:stop] + ' UTC')
        end

      end

      # A server usage entry
      #
      # ==== Attributes
      # * +name+ - The name of the server this entry is related
      # * +vcpus+ - Virtual CPU used by the server in the timespan (+started_at+ - +ended_at+ or +uptime+) for this entry
      # * +memory_mb+ - Memory (MBytes) used by the server in the timespan (+started_at+ - +ended_at+ or +uptime+) for this entry
      # * +local_gb+ - The amount of storage used over the uptime (GBytes)
      # * +flavor+ - The flavor id used by the server in this server usage entry
      # * +state+ - Current state for the server in this server usage entry
      # * +uptime+ - The uptime of this server in seconds
      # * +instance_id+ - Instance id of the server
      # * +hours+ - The uptime of this server in hours
      # * +tenant_id+ - The tenant id for this server usage entry
      class ServerUsage < Base

        schema do
          attribute :name, :string
          attribute :vcpus, :integer
          attribute :uptime, :integer
          attribute :instance_id, :integer
          attribute :hours, :float
          attribute :local_gb, :integer
          attribute :tenant_id, :string
          attribute :flavor, :string
          attribute :state, :string
          attribute :memory_mb, :integer
          attribute :started_at, :datetime
          attribute :ended_at, :datetime
        end

        # The initial date for this server usage entry
        def started_at
          DateTime.parse(@attributes[:started_at] + ' UTC')
        end

        # The final date for this server usage entry (can be nil if the server is still alive)
        def ended_at
          return nil if @attributes[:ended_at].blank?
          DateTime.parse(@attributes[:ended_at] + ' UTC')
        end

      end

    end
  end
end
