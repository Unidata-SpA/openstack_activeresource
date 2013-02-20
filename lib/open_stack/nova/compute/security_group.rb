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

      # An OpenStack Security Group
      #
      # ==== Attributes
      # * +tenant_id+ - Tenant id for this security group
      # * +name+ - Name of this security group
      # * +description+ - Description of this security group
      class SecurityGroup < Base
        self.element_name = "security_group"
        self.collection_name = "os-security-groups"

        schema do
          attribute :tenant_id, :string
          attribute :name, :string
          attribute :description, :string
        end

        validates :name,
                  :presence => true
        validates :description,
                  :presence => true

      end

      # An OpenStack Security Group Rule
      #
      # ==== Attributes
      # * +ip_protocol+ - Protocol: tcp, udp or icmp
      # * +from_port+ - Initial port
      # * +to_port+ - Final port
      # * +parent_group_id+ - The security group this rule belongs to
      # * +cidr+ - A cidr
      class Rule < Base
        self.element_name = "security_group_rule"
        self.collection_name = "os-security-group-rules"

        schema do
          attribute :ip_protocol, :string
          attribute :from_port, :integer
          attribute :to_port, :integer
          attribute :parent_group_id, :string
          attribute :cidr, :string
        end

        validates :ip_protocol, :presence => true, :inclusion => {:in => %w(tcp udp icmp)}
        validates :cidr, :presence => true, :format => {:with => OpenStack::IPV4_CIDR_REGEX}
        validates :parent_group_id, :presence => true
        validates :from_port, :presence => true, :numericality => {:only_integer => true}
        validates :to_port, :presence => true, :numericality => {:only_integer => true}

        validates_numericality_of :from_port, :less_than_or_equal_to => 255, :greater_than_or_equal_to => -1, :if => Proc.new { |rule| rule.icmp? }
        validates_numericality_of :from_port, :less_than_or_equal_to => 65535, :greater_than_or_equal_to => 1, :if => Proc.new { |rule| rule.udp? or rule.tcp? }

        validates_numericality_of :to_port, :less_than_or_equal_to => 255, :greater_than_or_equal_to => -1, :if => Proc.new { |rule| rule.icmp? }
        validates_numericality_of :to_port, :less_than_or_equal_to => 65535, :greater_than_or_equal_to => 1, :if => Proc.new { |rule| rule.udp? or rule.tcp? }
        validates_numericality_of :to_port, :greater_than_or_equal_to => :from_port, :if => Proc.new { |rule| rule.udp? or rule.tcp? }


        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :ip_protocol => attributes[:ip_protocol],
              :from_port => attributes[:from_port],
              :to_port => attributes[:to_port],
              :cidr => attributes[:cidr] || (attributes[:ip_range].present? ? attributes[:ip_range][:cidr] : nil),
              :parent_group_id => attributes[:parent_group].present? ? attributes[:parent_group].id : nil
          }
          super(new_attributes, persisted)
        end

        # Override ActiveRecord::encode method
        def encode(options={}) #:nodoc: Custom encoding to deal with openstack API
          to_encode = {
              :security_group_rule => {
                  :ip_protocol => ip_protocol,
                  :from_port => from_port,
                  :to_port => to_port,
                  :cidr => cidr,
                  :parent_group_id => parent_group_id,
              }
          }
          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # Set the parent security group (if the rule is not persisted)
        #
        # ==== Attributes
        # * +group+: An instance of OpenStack::Nova::Compute::SecurityGroup or a security group id
        def parent_group=(group)
          unless persisted?
            @parent_group = nil
            self.parent_group_id = group.is_a?(OpenStack::Nova::Compute::SecurityGroup) ? group.id : group
          end
        end

        # Parent group for this rule
        def parent_group
          unless parent_group_id.nil?
            @parent_group ||= SecurityGroup.find(parent_group_id)
          end
        end

        # True if this rule refers to ICMP
        def icmp?
          ip_protocol == 'icmp'
        end

        # True if this rule refers to UDP
        def udp?
          ip_protocol == 'udp'
        end

        # True if this rule refers to TCP
        def tcp?
          ip_protocol == 'tcp'
        end

      end

    end
  end
end
