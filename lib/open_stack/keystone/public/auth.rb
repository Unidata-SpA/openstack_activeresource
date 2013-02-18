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

      # End user authentication
      class Auth < Base
        self.element_name = "token"

        schema do
          attribute :username, :string
          attribute :password, :string
          attribute :tenant_id, :string
        end

        validates :username,
                  :presence => true,
                  :unless => Proc.new { token.present? }
        validates :password,
                  :presence => true,
                  :unless => Proc.new { token.present? }

        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes[:username] ||= ""
          attributes[:password] ||= ""

          if attributes[:tenant].present?
            attributes[:tenant_id] = attributes[:tenant].id
          elsif attributes[:tenant_id].present?
            attributes[:tenant_id] = attributes[:tenant_id]
          end

          super(attributes, persisted)
        end

        # Overloads ActiveRecord::encode method
        def encode(options={}) #:nodoc: Custom encoding to deal with openstack API
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

        def save #:nodoc: Catch some exceptions to perform "remote validation" of this resource
          super
        rescue ActiveResource::UnauthorizedAccess
          errors.add :password, I18n.t(:is_invalid)
          return false
        end

        # Returns the service catalog for current authentication
        def service_catalog
          @attributes[:serviceCatalog].is_a?(Array) ? @attributes[:serviceCatalog] : []
        end

        # Returns the OpenStack::Keystone::Public::Auth::Token instance for current authentication
        def token
          @attributes[:token]
        end

        # Returns the token_id (string) for current authentication
        def token_id
          token.id if token.present?
        end

        # Returns the list of endpoint for current authentication and for a given endpoint_type and region
        #
        # ==== Attributes
        # * +endpoint_type+ - The type of endpoint. Currently valid values are: "Compute", "Volume"
        # * +region+ - Restrict the search to given a region (can be omitted)
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

        # Returns the first endpoint for current authentication and for a given endpoint_type and region
        #
        # ==== Attributes
        # * +endpoint_type+ - The type of endpoint. Currently valid values are: "Compute", "Volume"
        # * +region+ - Restrict the search to given a region (can be omitted)
        def endpoint_for(endpoint_type, region=nil)
          endpoints_for(endpoint_type, region)[0]
        end

      end

      # Authentication Token
      class Auth::Token < Base
        schema do
          attribute :expires, :string
        end

        def initialize(attributes = {}, persisted = false) #:notnew:
          attributes = attributes.with_indifferent_access
          new_attributes = {
              :id => attributes[:id],
              :expires => attributes[:expires]
          }

          super(new_attributes, persisted)
        end

        # Expiration date and time for this token
        def expires_at
          DateTime.strptime(attributes[:expires], OpenStack::DATETIME_FORMAT)
        end

        # True if the token is expired
        def expired?
          DateTime.strptime(attributes[:expires], OpenStack::DATETIME_FORMAT) < DateTime.now.utc
        end

      end

    end
  end
end
