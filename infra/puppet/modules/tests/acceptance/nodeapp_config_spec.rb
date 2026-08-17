control 'nodeapp-config-complete' do
  describe file('/opt/nodeapp/.env') do
    its('content') { should match(/NODE_ENV=/) }
    its('content') { should match(/FEATURE_FLAG_NEW_CHECKOUT=/) }
    its('content') { should match(/SESSION_SECRET_KEY_VAULT_REF=/) }
    its('content') { should match(/PORT=/) }
    its('content') { should match(/DB_HOST=/) }
    its('content') { should match(/DB_NAME=/) }
    its('content') { should match(/LOG_LEVEL=/) }
  end
end
