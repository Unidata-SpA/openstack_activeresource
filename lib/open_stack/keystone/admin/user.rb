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

      # An OpenStack User ("admin view")
      #
      # ==== Attributes
      # * +name+ - The name of this user
      # * +password+ - Password (possibly encrypted) of this user
      # * +email+ - E-mail address of this user
      # * +enabled+ - True if this user is enabled
      # * +tenant_id+ - Default (i.e. primary) tenant for this user
      class User < Base

        schema do
          attribute :name, :string
          attribute :password, :string
          attribute :email, :string
          attribute :enabled, :boolean
          attribute :tenant_id, :string
        end

        validates :name,
                  :presence => true,
                  :length => {:minimum => 4, :allow_blank => true},
                  :format => {:with => /\A[0-9a-z_]+\Z/i, :allow_blank => true}
        validates :password,
                  :presence => true,
                  :format => {:with => /(?=.*[\d\W])/, :message => :must_contain_at_least_one_digit_or_one_special_character, :allow_blank => true},
                  :length => {:minimum => 8, :allow_blank => true}
        validates :email,
                  :presence => true,
                  :formate => {:with => /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\Z/i, :allow_blank => true}
        validates :enabled,
                  :presence => true,
                  :inclusion => {:in => [true, false], :allow_blank => true}

        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes = attributes.with_indifferent_access

          if attributes[:tenant].present?
            attributes[:tenant_id] = attributes.delete(:tenant).id
          end

          if attributes[:tenantId].present?
            attributes[:tenant_id] = attributes.delete(:tenantId)
          end

          super(attributes, persisted)
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) #:nodoc: Custom encoding to deal with openstack API
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

        # List of users in a given tenant
        #
        # ==== Attributes
        # * +tenant+ - An instance of OpenStack::Keystone::Admin::Tenant or a tenant id
        def self.all_by_tenant(tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          all.select { |user| user.tenant_id == tenant_id }
        end

        # Find a user in a given tenant
        #
        # ==== Attributes
        # * +id+ - The user id
        # * +tenant+ - An instance of OpenStack::Keystone::Admin::Tenant or a tenant id
        def self.find_by_tenant(id, tenant)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : tenant

          user = self.find(id)
          user.tenant_id == tenant_id ? user : nil
        end

        # List of user with a given name
        #
        # ==== Attributes
        # * +name+ - A string
        def self.find_by_name(name)
          all.detect { |user| user.name == name }
        end

        # The primary (default) tenant (i.e. an instance of OpenStack::Keystone::Admin::Tenant) associated with this user
        def tenant
          OpenStack::Keystone::Admin::Tenant.find tenant_id
        end

        # File role(s) (i.e. instances of OpenStack::Keystone::Admin::UserRole) for this user in a given tenant
        #
        # ==== Attributes
        # * +scope+ - The ActiveResource scope (defaults to :all)
        # * +tenant+ - An optional instance of OpenStack::Keystone::Admin::Tenant (or a tenant id). Defaults to the primary tenant for this user
        def roles(scope = :all, tenant = nil)
          tenant_id = tenant.is_a?(OpenStack::Keystone::Admin::Tenant) ? tenant.id : (tenant || self.tenant_id)

          OpenStack::Keystone::Admin::UserRole.find(scope, :params => {:tenant_id => tenant_id, :user_id => self.id})
        end

      end

    end
  end
end
