require 'spec_helper'

describe 'deployment' do

  context 'with defaults for all parameters' do
    it { should contain_class('deployment') }
  end
end
