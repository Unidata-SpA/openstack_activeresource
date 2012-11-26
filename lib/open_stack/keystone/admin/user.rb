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
  module Keystone
    module Admin

      class User < Base

        schema do
          attribute :name, :string
          attribute :password, :string
          attribute :email, :string
          attribute :enabled, :boolean
          attribute :tenant_id, :string
        end

        validates :name, :presence => true
        validates_length_of :name, :minimum => 4
        validates_format_of :name, :with => /\A[0-9a-z_]+\Z/i
        validates_format_of :password, :with => /(?=.*[\d\W])/, :message => :must_contain_at_least_one_digit_or_one_special_character
        validates_length_of :password, :minimum => 8
        validates_format_of :email, :with => /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\Z/i
        validates :enabled, :presence => true, :inclusion => {:in => [true, false]}

        def initialize(attributes = {}, persisted = false)
          attributes = attributes.with_indifferent_access

          if attributes[:tenant].present?
            attributes[:tenant_id] = attributes.delete(:tenant).id
          end

          if attributes[:tenantId].present?
            attributes[:tenant_id] = attributes.delete(:tenantId)
          end

          super(attributes, persisted)
        end

        # Overload ActiveRecord::encode method
        # Custom encoding to deal with openstack API
        def encode(options={})
          to_encode = {
              :user => {
                  :name => name,
                  :password => password,
                  :email => email,
                  :enabled => enabled
              }
          }

          to_encode[:user][:tenantId] = tenant_id if @attributes[:tenant_id].present?

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        def self.all_by_tenant(tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          all.select { |user| user.tenant_id == tenant_id }
        end

        def self.find_by_tenant(id, tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          user = self.find(id)
          user.tenant_id == tenant_id ? user : nil
        end

        def self.find_by_name(name)
          all.each { |user| return user if user.name == name }

          nil
        end

        def roles(scope = :all)
          OpenStack::Keystone::Admin::UserRole.find(scope, :params => { :tenant_id => self.tenant_id, :user_id => self.id })
        end

      end

    end
  end
end
