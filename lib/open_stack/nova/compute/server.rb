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

      # An OpenStack Server
      #
      # ==== Attributes
      # * +name+ - The name of the server
      # * +status+ - Status of the server (see http://docs.openstack.org/api/openstack-compute/2/content/List_Servers-d1e2078.html)
      # * +vm_state+ - Extended Instance Status
      # * +task+ - If not +nil+, contains the task OpenStack is preforming on this server
      # * +power_state+ - Server power state (0|1)
      # * +tenant_id+ - Identifier of the tenant this server belongs to
      # * +user_id+ - Identifier of the user that created this server
      # * +image_id+ - Identifier of the image used to create this server
      # * +flavor_id+ - Identifier of the flavor used to create this server
      # * +key_pair_id+ - Identifier of the keypair used by this server
      # * +updated_at+ - Last modification timestamp
      # * +created_at+ - Creation timestamp
      class Server < BaseDetail

        schema do
          attribute :name, :string
          attribute :status, :string
          attribute :updated_at, :datetime
          attribute :created_at, :datetime
          attribute :vm_state, :string
          attribute :task, :string
          attribute :power_state, :integer
          attribute :host_id, :string
          attribute :tenant_id, :string
          attribute :user_id, :string
          attribute :image_id, :string
          attribute :flavor_id, :string
          attribute :key_pair_id, :string
        end

        validates :name,
                  :presence => true,
                  :format => {:with => /\A[\w\.\-\_]{2,}\Z/, :allow_blank => true},
                  :length => {:maximum => 255}
        validates :image,
                  :presence => true
        validates :flavor,
                  :presence => true

        # Return the list of server for a given tenant
        #
        # ==== Attributes
        # * +tenant+ - an OpenStack::Keystone::Admin::Tenant instance (or a tenant id)
        #
        # ==== Notes
        # This method require an admin access
        def self.all_by_tenant(tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          find(:all, :params => {:tenant_id => tenant_id})
        end

        def initialize(attributes = {}, persisted = false) # :notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :name => attributes[:name],
              :status => attributes[:status],
              :updated_at => attributes[:updated].present? ? DateTime.strptime(attributes[:updated], OpenStack::DATETIME_FORMAT) : nil,
              :created_at => attributes[:created].present? ? DateTime.strptime(attributes[:created], OpenStack::DATETIME_FORMAT) : nil,
              :vm_state => attributes[:'OS-EXT-STS:vm_state'],
              :task => attributes[:'OS-EXT-STS:task_state'],
              :power_state => attributes['OS-EXT-STS:power_state'],
              :host_id => attributes[:hostId],
              :user_data => attributes[:user_data],
          }

          if attributes[:key_pair].present?
            new_attributes[:key_pair_id] = attributes[:key_pair].name
          else
            new_attributes[:key_pair_id] = attributes[:key_name]
          end

          if attributes[:image].present?
            new_attributes[:image_id] = attributes[:image].is_a?(Image) ? attributes[:image].id : attributes[:image][:id]
          elsif attributes[:image_id].present?
            new_attributes[:image_id] = attributes[:image_id]
          end

          if attributes[:flavor].present?
            new_attributes[:flavor_id] = attributes[:flavor].is_a?(Flavor) ? attributes[:flavor].id : attributes[:flavor][:id]
          elsif attributes[:flavor_id].present?
            new_attributes[:flavor_id] = attributes[:flavor_id]
          end

          if persisted
            # We ignore the list of security group names provided in attributes[:security_group]
            # Security group ids will be retrieved when needed
            new_attributes[:security_group_ids] = []
          else

            if attributes[:security_group_ids].nil?
              new_attributes[:security_group_ids] = attributes[:security_groups].nil? ? [] : attributes[:security_groups].map { |sg| sg.id }
            else
              new_attributes[:security_group_ids] = attributes[:security_group_ids]
            end

          end

          super(new_attributes, persisted)

          self
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) # :nodoc: Custom encoding to deal with openstack API
          to_encode = {
              :server => {
                  :name => name,
                  :imageRef => image_id,
                  :flavorRef => flavor_id,
              }
          }

          # Optional attributes (openstack will not accept empty attribute for update/create)
          to_encode[:server][:user_data] = Base64.strict_encode64(user_data) if user_data.present?
          to_encode[:server][:key_name] = key_pair_id if key_pair_id.present?
          to_encode[:server][:security_groups] = security_groups.map { |sg| {:name => sg.name} }

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # The instance of OpenStack::Nova::Compute::Image used for this server
        def image
          if image_id.present?
            @image ||= Image.find(image_id)
          end
        end

        # Set the image for this server (if the server is not persisted)
        #
        # ==== Attributes
        # * +image+ - An instance of OpenStack::Nova::Compute::Image or an image id
        def image=(image)
          unless persisted?
            @image = nil # nullify @@image because the image id is changed
            self.image_id = image.is_a?(OpenStack::Nova::Compute::Image) ? image.id : image
          end
        end

        # The instance of OpenStack::Nova::Compute::Flavor used for this server
        def flavor
          if flavor_id.present?
            @flavor ||= Flavor.find(flavor_id)
          end
        end

        # Set the flavor for this server (if the server is not persisted)
        #
        # ==== Attributes
        # * +flavor+ - An instance of OpenStack::Nova::Compute::Flavor or a flavor id
        def flavor=(flavor)
          unless persisted?
            @flavor = nil # nullify @flavor because the flavor id is changed
            self.flavor_id = flavor.is_a?(OpenStack::Nova::Compute::Flavor) ? flavor.id : flavor
          end
        end

        # The instance of OpenStack::Nova::Compute::KeyPair used for this server (if any)
        def key_pair
          if key_pair_id.present?
            @keypair ||= KeyPair.find(key_pair_id)
          end
        end

        # Set the keypair for this server (if the server is not persisted)
        #
        # ==== Attributes
        # * +key_pair+ - An instance of OpenStack::Nova::Compute::KeyPair or a key-pair id
        def key_pair=(key_pair)
          unless persisted?
            @keypair = nil # nullify @@keypair because the keypair id is changed
            self.key_pair_id = key_pair.id
          end
        end

        # The array of OpenStack::Nova::Compute::SecurityGroup instances associated with this server
        def security_groups
          if persisted?
            get('os-security-groups').map { |sg| OpenStack::Nova::Compute::SecurityGroup.new(sg, true) }
          else
            security_group_ids.map { |sg_id| OpenStack::Nova::Compute::SecurityGroup.find sg_id }
          end
        end

        # Set security groups for this server
        #
        # ==== Attributes
        # * +security_groups+ - Array of OpenStack::Nova::Compute::SecurityGroup instances
        def security_groups=(security_groups)
          return if persisted? # Do Nothing (it's a read-only attribute for OpenStack)

          self.security_group_ids = security_groups.map { |sg| sg.id }

          security_groups
        end

        # Addresses hash associated to this server
        def addresses
          addresses = {}
          if persisted?
            response = get('ips')
            response.each do |net, address|
              addresses[net] = address
            end
          end
          addresses
        end

        def addresses=(something) # :nodoc: do Nothing (it's a read-only attribute for OpenStack)

        end

        # The OpenStack::Nova::Compute::VolumeAttachment(s) for this server
        #
        # ==== Attributes
        # * +scope+ - An ActiveResource find scope (default: :all)
        def volume_attachments(scope = :all)
          VolumeAttachment.find(scope, :params => {:server_id => self.id})
        end

        # Array of OpenStack::Nova::Compute::Volume attached to this server
        def attached_volumes
          volume_attachments.present? ? volume_attachments.map { |va| va.volume } : []
        end

        # Attach a volume
        #
        # ==== Attributes
        # * +volume+ - An OpenStack::Nova::Compute::Volume instance
        # * +device_name+ - Name the device (from server perspective) (e.g. "/dev/vdc")
        def attach_volume!(volume, device_name)
          VolumeAttachment.create(:volume => volume, :device => device_name, :server => self)
        end

        # Refresh server status
        # This method updates the following attributes:
        #  * progress
        #  * status
        #  * task
        #  * power_state
        #  * vm_state
        def refresh_status!
          if persisted?
            updated = Server.find(self.id)
            self.progress = updated.progress
            self.status = updated.status
            self.task = updated.task
            self.power_state = updated.power_state
            self.vm_state = updated.vm_state

            self
          end
        end

        SERVER_STATUSES = {
            :ACTIVE => I18n.t(:active, :scope => [:openstack, :status]),
            :BUILD => I18n.t(:building, :scope => [:openstack, :status]),
            :DELETED => I18n.t(:deleted, :scope => [:openstack, :status]),
            :ERROR => I18n.t(:in_error, :scope => [:openstack, :status]),
            :HARD_REBOOT => I18n.t(:hard_rebooting, :scope => [:openstack, :status]),
            :PASSWORD => I18n.t(:resetting_password, :scope => [:openstack, :status]),
            :REBOOT => I18n.t(:soft_rebooting, :scope => [:openstack, :status]),
            :REBUILD => I18n.t(:rebuilding_from_image, :scope => [:openstack, :status]),
            :RESCUE => I18n.t(:in_rescue_mode, :scope => [:openstack, :status]),
            :RESIZE => I18n.t(:resizing, :scope => [:openstack, :status]),
            :REVERT_RESIZE => I18n.t(:revert_resizing, :scope => [:openstack, :status]),
            :SHUTOFF => I18n.t(:user_powered_down, :scope => [:openstack, :status]),
            :SUSPENDED => I18n.t(:suspended, :scope => [:openstack, :status]),
            :PAUSED => I18n.t(:paused, :scope => [:openstack, :status]),
            :UNKNOWN => I18n.t(:unknown, :scope => [:openstack, :status]),
            :VERIFY_RESIZE => I18n.t(:awaiting_verification, :scope => [:openstack, :status])
        }.with_indifferent_access

        # Returns an extended (and localized) description for the server status
        def status_description
          SERVER_STATUSES[status]
        end

        # Returns a localized description for the server task (if any)
        def task_description
          I18n.t(task, :scope => [:openstack, :tasks]) if task.present?
        end

        # Assign a floating IP to the server
        #
        # ==== Attributes
        # * +floating_ip+ - a FloatingIP to be attached to the server.
        def add_floating_ip(floating_ip)
          post(:action, {}, {:addFloatingIp => {:address => floating_ip.ip}}.to_json)
        end

        # Reboot the server
        #
        # ==== Attributes
        # * +type+ - type of reboot. Should be 'hard' or 'soft' (defaults to 'hard', may be nil)
        def reboot(type=:hard)
          post(:action, {}, {:reboot => {:type => type}}.to_json)
        end

        # Creates a new snapshot of server
        #
        # ==== Attributes
        # * +name+ - name of the new snapshot image
        # * +metadata+ -  hash of metadata (may be nil)
        def create_new_image(name, metadata={})
          post(:action, {}, {:createImage => {:name => name, :metadata => metadata}}.to_json)
        end

        # Gets the output from the console log for a server
        #
        # ==== Attributes
        # * +length+ - numbers of lines to get (defaults to 50, may be nil)
        def console_output(length=50)
          response = post(:action, {}, {:'os-getConsoleOutput' => {:length => length}}.to_json)

          ActiveSupport::JSON.decode(response.body)['output']
        end

        # Accesses a VNC console for a specific server
        #
        # ==== Attributes
        # * +length+ - numbers of lines to get (defaults to 50, may be nil)
        def vnc_console(type='novnc')
          response = post(:action, {}, {:'os-getVNCConsole' => {:type => type}}.to_json)

          ActiveSupport::JSON.decode(response.body)['console']['url']
        end

        # Halts a running server. Changes status to STOPPED.
        def stop
          post(:action, {}, {:'os-stop' => nil}.to_json)
        end

        # Returns a STOPPED server to ACTIVE status.
        def start
          post(:action, {}, {:'os-start' => nil}.to_json)
        end

        # PAUSE a server.
        def pause
          post(:action, {}, {:'pause' => nil}.to_json)
        end

        # Returns a PAUSED server to ACTIVE status.
        def unpause
          post(:action, {}, {:'unpause' => nil}.to_json)
        end

        # Suspend a running server. Changes status to SUSPENDED.
        def suspend
          post(:action, {}, {:'suspend' => nil}.to_json)
        end

        # Resume a SUSPENDED server.
        def resume
          post(:action, {}, {:'resume' => nil}.to_json)
        end

        # true if the status is ACTIVE
        def active?
          status == "ACTIVE"
        end

        # true if the status is PAUSED
        def paused?
          status == "PAUSED"
        end

        # true if the status is SHUTOFF
        def shutoff?
          status == "SHUTOFF"
        end

        # true if the status is DELETED
        def deleted?
          status == "DELETED"
        end

      end

    end
  end
end
