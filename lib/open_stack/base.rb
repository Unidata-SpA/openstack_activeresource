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

  DATETIME_FORMAT="%Y-%m-%dT%H:%M:%S"
  IPV4_REGEX= /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  IPV4_CIDR_REGEX= /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/(3[0-2]|[1-2][0-9]|[0-9])\Z/

  class Base < ActiveResource::Base

    self.format = :json
    self.timeout = 5

    def self.headers
      if defined?(@headers)
        _headers = @headers
      elsif self != OpenStack::Base && superclass.headers
        _headers = superclass.headers
      else
        _headers = @headers || {}
      end

      if self.token.present?
        _headers['X-Auth-Token'] = self.token.id
      end

      _headers
    end

    protected

    def self.token=(token)
      Thread.current[:open_stack_token] = token
    end

    def self.token
      Thread.current[:open_stack_token]
    end

  end

end

# Reopen ActiveResource::ClientError to add the proper parsing for OpenStack errors
class ActiveResource::ClientError < ActiveResource::ConnectionError
  alias old_message message
  alias old_to_s to_s

  def message
    decoded_error = decode_openstack_error
    decoded_error.nil? ? old_message : decoded_error
  rescue Exception => e
    # Fallback to the original method
    old_message
  end

  def to_s
    decoded_error = decode_openstack_error
    decoded_error.nil? ? old_to_s : decoded_error
  rescue Exception => e
    # Fallback to the original method
    old_to_s
  end

  private

  def decode_openstack_error
    decoded_body = ActiveSupport::JSON.decode(self.response.body)

    decoded_body[decoded_body.keys[0]]['message']
  end

end
