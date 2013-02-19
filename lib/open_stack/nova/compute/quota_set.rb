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

      # An OpenStack Quota-Set
      #
      # ==== Attributes
      # * +instances+ - Number of permitted instances
      # * +cores+ - Number of instanceable cores
      # * +ram+ - Quantity of instanceable RAM (MBytes)
      # * +floating_ips+ - Number of floating IP
      # * +key_pairs+ - Number of keypairs
      # * +metadata_items+ - Metadata items permitted
      # * +security_groups+ - Number of security groups permitted
      # * +security_group_rules+ - Number of rules per security group permitted
      # * +injected_files+ - Number of injectable files
      # * +injected_file_content_bytes+ - Injected file maximum length
      # * +injected_file_path_bytes+ - Injected file path name maximum length
      class QuotaSet < Base
        self.collection_name = "os-quota-sets"

        schema do
          attribute :instances, :integer
          attribute :cores, :integer
          attribute :ram, :integer
          attribute :floating_ips, :integer
          attribute :key_pairs, :integer
          attribute :metadata_items, :integer
          attribute :security_groups, :integer
          attribute :security_group_rules, :integer
          attribute :injected_files, :integer
          attribute :injected_file_content_bytes, :integer
          attribute :injected_file_path_bytes, :integer
        end

        validates :cores,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :floating_ips,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :injected_file_content_bytes,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :injected_file_path_bytes,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :injected_files,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :instances,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :key_pairs,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :metadata_items,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :ram,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :security_group_rules,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}
        validates :security_groups,
                  :presence => true,
                  :numericality => {:greater_than_or_equal_to => 1, :allow_blank => true}

      end

    end
  end
end