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

        validates :name, :format => {:with => /\A[\w\.\-\_]{2,}\Z/}, :length => {:maximum => 255}
        validates :image, :presence => true
        validates :flavor, :presence => true

        def self.all_by_tenant(tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          find(:all, :params => {:tenant_id => tenant_id})
        end

        def initialize(attributes = {}, persisted = false)
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
              # :tenant_id => attributes[:tenant_id],
              # :user_id => attributes[:user_id],
              :addresses => attributes[:addresses] || []
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

            new_attributes[:security_group_ids] = attributes[:security_group_ids] || attributes[:security_groups].map { |sg| sg.id }
          end

          super(new_attributes, persisted)

          self
        end

        # Overload ActiveRecord::encode method
        # Custom encoding to deal with openstack API
        def encode(options={})
          to_encode = {
              :server => {
                  :name => name,
                  :imageRef => image_id,
                  :flavorRef => flavor_id,
              }
          }

          # Optional attributes (openstack will not accept empty attribute for update/create)
          to_encode[:server][:user_data] = Base64.encode64(user_data) if user_data.present?
          to_encode[:server][:key_name] = key_pair_id if key_pair_id.present?
          to_encode[:server][:security_groups] = security_groups.map { |sg| {:name => sg.name} }

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # Accessors

        def image
          Image.find(image_id) if image_id.present?
        end

        def image=(image)
          self.image_id = image.id
        end

        def flavor
          Flavor.find(flavor_id) if flavor_id.present?
        end

        def flavor=(flavor)
          self.flavor_id = flavor.id
        end

        def key_pair
          KeyPair.find(key_pair_id) if key_pair_id.present?
        end

        def key_pair=(key_pair)
          self.key_pair_id = key_pair.name
        end

        def security_groups
          if persisted?
            get('os-security-groups').map { |sg| OpenStack::Nova::Compute::SecurityGroup.new(sg, true) }
          else
            security_group_ids.map { |sg_id| OpenStack::Nova::Compute::SecurityGroup.find sg_id }
          end
        end

        def security_groups=(security_groups)
          return if persisted? # Do Nothing (it's a read-only attribute for OpenStack)

          security_group_ids = security_groups.map { |sg| sg.id }

          security_groups
        end

        def addresses
          addresses = {}
          if persisted?
            response = get('ips')
            response.each { |net, address|
              addresses[net] = address
            }
          else
            attributes[:addresses]
          end
        end

        def addresses=(something)
          # Do Nothing (it's a read-only attribute for OpenStack)
        end

        def volume_attachments(scope = :all)
          VolumeAttachment.find(scope, :params => {:server_id => self.id})
        end

        # Misc...

        # Return the list of attached volumes
        def attached_volumes
          volume_attachments.present? ? volume_attachments.map { |va| va.volume } : []
        end

        # Attach a volume
        def attach_volume!(volume, device_name)
          VolumeAttachment.create(:volume => volume, :device => device_name, :server => self)
        end

        # Refresh server status
        def refresh_status!
          updated = Server.find(self.id)
          self.progress = updated.progress
          self.status = updated.status
          self.task = updated.task

          self
        end

        SERVER_STATUSES = {
            :ACTIVE => I18n.t(:active),
            :BUILD => I18n.t(:builing),
            :DELETED => I18n.t(:deleted),
            :ERROR => I18n.t(:in_error),
            :HARD_REBOOT => I18n.t(:hard_rebooting),
            :PASSWORD => I18n.t(:resetting_password),
            :REBOOT => I18n.t(:soft_rebooting),
            :REBUILD => I18n.t(:rebuilding_from_image),
            :RESCUE => I18n.t(:in_rescue_mode),
            :RESIZE => I18n.t(:resizing),
            :REVERT_RESIZE => I18n.t(:revert_resizing),
            :SHUTOFF => I18n.t(:user_powered_down),
            :SUSPENDED => I18n.t(:suspended),
            :PAUSED => I18n.t(:paused),
            :UNKNOWN => I18n.t(:unknown),
            :VERIFY_RESIZE => I18n.t(:awaiting_verification)
        }.with_indifferent_access

        # Returns an extended description for the server status
        def status_description
          SERVER_STATUSES[status]
        end

        ## Actions

        # Assign a floating IP to the server.
        # Params:
        # +floating_ip+:: a FloatingIP to be attached to the server.
        def add_floating_ip(floating_ip)
          post(:action, {}, {:addFloatingIp => {:address => floating_ip.ip}}.to_json)
        end

        # Reboot the server.
        # Params:
        # +type+:: type of reboot. Should be 'hard' or 'soft' (defaults to 'hard', may be nil)
        def reboot(type=:hard)
          post(:action, {}, {:reboot => {:type => type}}.to_json)
        end

        # Creates a new snapshot of server.
        # Params:
        # +name+:: name of the new snapshot image
        # +metadata+::  hash of metadata (may be nil)
        def create_new_image(name, metadata={})
          post(:action, {}, {:createImage => {:name => name, :metadata => metadata}}.to_json)
        end

        # Gets the output from the console log for a server.
        # Params:
        # +length+:: numbers of lines to get (defaults to 50, may be nil)
        def console_output(length=50)
          response = post(:action, {}, {:'os-getConsoleOutput' => {:length => length}}.to_json)

          ActiveSupport::JSON.decode(response.body)['output']
        end

        # Accesses a VNC console for a specific server.
        # Params:
        # +length+:: numbers of lines to get (defaults to 50, may be nil)
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

      end

    end
  end
end
