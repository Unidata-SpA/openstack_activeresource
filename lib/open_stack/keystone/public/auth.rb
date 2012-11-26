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
    module Public

      class Auth < Base
        self.element_name = "token"

        schema do
          attribute :username, :string
          attribute :password, :string
          attribute :tenant_id, :string
        end

        validates :username, :presence => true, :unless => Proc.new { token.present? }
        validates :password, :presence => true, :unless => Proc.new { token.present? }

        def initialize(attributes = {}, persisted = false)
          attributes[:username] ||= ""
          attributes[:password] ||= ""

          if attributes[:tenant].present?
            attributes[:tenant_id] = attributes[:tenant].id
          elsif attributes[:tenant_id].present?
            attributes[:tenant_id] = attributes[:tenant_id]
          end

          super(attributes, persisted)
        end

        # Overload ActiveRecord::encode method
        # Custom encoding to deal with openstack API
        def encode(options={})
          to_encode = {}
          if token.present?
            to_encode[:auth] = {
                :token => {
                    :id => token_id
                }
            }
          else
            to_encode[:auth] = {
                :passwordCredentials => {
                    :username => username,
                    :password => password
                }
            }
          end

          to_encode[:auth][:tenantId] = tenant_id if @attributes[:tenant_id].present?

          to_encode.send("to_#{self.class.format.extension}", options)
        end

        # Catch some exceptions to perform "remote validation" of this resource
        def save
          super
        rescue ActiveResource::UnauthorizedAccess
          errors.add :password, I18n.t(:is_invalid)
          return false
        end

        def service_catalog
          @attributes[:serviceCatalog].is_a?(Array) ? @attributes[:serviceCatalog] : []
        end

        def token
          @attributes[:token]
        end

        def token_id
          token.id if token.present?
        end

        def endpoints_for(endpoint_type, region=nil)
          return [] unless service_catalog.present?

          endpoints = []
          service_catalog.each { |c|
            next if c.attributes[:type] != endpoint_type

            c.endpoints.each { |e|
              if region.nil? or e.region == region
                endpoints << e
              end
            }
          }

          endpoints
        end

        def endpoint_for(endpoint_type, region=nil)
          endpoints_for(endpoint_type, region)[0]
        end

      end

      class Auth::Token < Base
        schema do
          attribute :expires, :string
        end

        def initialize(attributes = {}, persisted = false)
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :expires => attributes[:expires]
          }

          super(new_attributes, persisted)
        end

        def expires_at
          DateTime.strptime(attributes[:expires], OpenStack::DATETIME_FORMAT)
        end

        def expired?
          DateTime.strptime(attributes[:expires], OpenStack::DATETIME_FORMAT) < DateTime.now.utc
        end

      end

    end
  end
end
