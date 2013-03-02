module OpenstackTestUtils

  private

  def auth_admin
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]
    OpenStack::Keystone::Admin::Base.site = TEST_CONFIG[:public_admin_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:admin_username],
                                                    :password => TEST_CONFIG[:admin_password],
                                                    :tenant_id => TEST_CONFIG[:admin_tenant_id]

    OpenStack::Base.token = auth.token
    OpenStack::Nova::Compute::Base.site = auth.endpoint_for('compute').publicURL
    OpenStack::Nova::Volume::Base.site = auth.endpoint_for('volume').publicURL

  end

  def auth_user
    OpenStack::Keystone::Public::Base.site = TEST_CONFIG[:public_base_site]

    auth = OpenStack::Keystone::Public::Auth.create :username => TEST_CONFIG[:user_username],
                                                    :password => TEST_CONFIG[:user_password],
                                                    :tenant_id => TEST_CONFIG[:user_tenant_id]

    OpenStack::Base.token = auth.token
    OpenStack::Nova::Compute::Base.site = auth.endpoint_for('compute').publicURL
    OpenStack::Nova::Volume::Base.site = auth.endpoint_for('volume').publicURL

  end

  def admin_test_possible?
    TEST_CONFIG[:admin_username] and TEST_CONFIG[:admin_password] and TEST_CONFIG[:admin_tenant_id]
  end

  def loop_block(seconds=10)
    ret = nil
    if block_given? and seconds > 0
      begin
        ret = yield
        return ret unless ret.nil?
        seconds-=1
        sleep 1
      end while seconds > 0
    end

    ret
  end

  def active_resource_errors_to_s(active_resource)
    message = ""
    active_resource.errors.messages.each_pair { |k, v|
      message += "#{k}: " + v.join(",") + ". \n"
    }

    message
  end

end