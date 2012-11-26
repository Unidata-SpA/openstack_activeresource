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

      class SecurityGroup < Base
        self.element_name = "os-security-group"
        self.collection_name = "os-security-groups"

        schema do
          attribute :tenant_id, :string
          attribute :name, :string
          attribute :description, :string
        end

        validates :name, :presence => true
        validates :description, :presence => true

      end

      class SecurityGroup::Rule < Base
        self.element_name = "os-security-group-rule"
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


        def initialize(attributes = {}, persisted = false)
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :ip_protocol => attributes[:ip_protocol],
              :from_port => attributes[:from_port],
              :to_port => attributes[:to_port],
              :cidr => attributes[:cidr] || attributes[:ip_range][:cidr],
              :parent_group_id => attributes[:parent_group].present? ? attributes[:parent_group].id : nil
          }
          super(new_attributes, persisted)
        end

        # Overload ActiveRecord::encode method
        # Custom encoding to deal with openstack API
        def encode(options={})
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

        def parent_group=(group)
          parent_group_id = group.id
        end

        def parent_group
          return nil if parent_group_id.nil?
          SecurityGroup.find(parent_group_id)
        end

        def icmp?
          ip_protocol == 'icmp'
        end

        def udp?
          ip_protocol == 'udp'
        end

        def tcp?
          ip_protocol == 'tcp'
        end

      end

    end
  end
end

