require 'spec_helper'

describe 'nodeapp' do
  ['dev', 'test', 'prod'].each do |env|
    context "on environment #{env}" do
      let(:facts) { { server_facts: { environment: env } } }

      it { is_expected.to compile.with_all_deps }

      it 'renders .env with all required keys' do
        is_expected.to contain_file('/opt/nodeapp/.env')
          .with_content(/FEATURE_FLAG_NEW_CHECKOUT=/)
          .with_content(/NODE_ENV=/)
          .with_content(/DB_HOST=/)
      end
    end
  end
end
