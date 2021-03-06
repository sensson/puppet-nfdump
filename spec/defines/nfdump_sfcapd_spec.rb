require 'spec_helper'
describe 'nfdump::sfcapd', type: :define do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        let :title do
          'sw1'
        end

        context 'nfdump::sfcapd without parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('nfdump') }
          it { is_expected.to contain_class('systemd') }

          it { is_expected.to contain_file('/data/nfdump/sources/sw1') }
          it { is_expected.to contain_file('/data/nfdump/sources/sw1').with_ensure('directory') }
          it { is_expected.to contain_file('/data/nfdump/sources/sw1').with_owner('sflow') }
          it { is_expected.to contain_file('/data/nfdump/sources/sw1').with_group('sflow') }
          it { is_expected.to contain_file('/data/nfdump/sources/sw1').that_requires('File[/data/nfdump/sources]') }
          it { is_expected.to contain_file('/data/nfdump/sources/sw1').that_requires('User[sflow]') }

          it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service') }
          it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').with_content(%r{/usr/bin/sfcapd -w -D -p 6343 -u sflow -g sflow -B 200000 -S 1 -P /data/nfdump/sw1.pid -z -T all -I sw1 -l /data/nfdump/sources/sw1}) }
          it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').without_content(/-R/) }
          it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').that_requires('File[/data/nfdump/sources/sw1]') }

          it { is_expected.to contain_service('sfcapd-sw1') }
          it { is_expected.to contain_service('sfcapd-sw1').with_ensure('running') }
          it { is_expected.to contain_service('sfcapd-sw1').that_requires('Systemd::Unit_file[sfcapd-sw1.service]') }
          it { is_expected.to contain_service('sfcapd-sw1').that_requires('Exec[systemctl-daemon-reload]') }

          case facts[:osfamily]
          when 'RedHat'
            it { is_expected.to contain_file('/etc/sysconfig/sfcapd-sw1') }
            it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').that_requires('File[/etc/sysconfig/sfcapd-sw1]') }
            it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').that_requires('Package[nfdump]') }
          when 'Debian'
            it { is_expected.to contain_file('/etc/default/sfcapd-sw1') }
            it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').that_requires('File[/etc/default/sfcapd-sw1]') }
            it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').that_requires('Package[nfdump-sflow]') }
          end
        end

        context 'nfdump::sfcapd with the source parameter set' do
          # Source overrides our title
          let(:params) do
            {
              source: 'sw2'
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/data/nfdump/sources/sw2') }
          it { is_expected.to contain_systemd__unit_file('sfcapd-sw2.service') }
          it { is_expected.to contain_service('sfcapd-sw2') }

          case facts[:osfamily]
          when 'RedHat'
            it { is_expected.to contain_file('/etc/sysconfig/sfcapd-sw2') }
          when 'Debian'
            it { is_expected.to contain_file('/etc/default/sfcapd-sw2') }
          end
        end

        context 'nfdump::sfcapd with repeater host set' do
          # Source overrides our title
          let(:params) do
            {
              repeater_host: '192.168.124.125'
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_systemd__unit_file('sfcapd-sw1.service').with_content(%r{-R 192.168.124.125/6343}) }
        end
      end
    end
  end
end
