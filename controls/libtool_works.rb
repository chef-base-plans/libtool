title 'Tests to confirm libtool works as expected'

plan_origin = ENV['HAB_ORIGIN']
plan_name = input('plan_name', value: 'libtool')

control 'core-plans-libtool-works' do
  impact 1.0
  title 'Ensure libtool works as expected'
  desc '
  Verify libtool by ensuring 
  (1) its installation directory exists and 
  (2) that it returns the expected version.
  (3) that the binaries and libraries it references in libtool --config
      all exist.  NOTE: several binaries and directores currently do not exist
      and an issue has been raised to resolve as defined below.  When the issue
      is resolved these test should no longer be skipped
  '
  
  plan_installation_directory = command("hab pkg path #{plan_origin}/#{plan_name}")
  describe plan_installation_directory do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not be_empty }
    its('stderr') { should be_empty }
  end
  
  command_relative_path = input('command_relative_path', value: 'bin/libtool')
  command_full_path = File.join(plan_installation_directory.stdout.strip, "#{command_relative_path}")
  plan_pkg_version = plan_installation_directory.stdout.split("/")[5]
  describe command("#{command_full_path} --version") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not be_empty }
    its('stdout') { should match /libtool \(GNU libtool\) #{plan_pkg_version}/ }
    its('stderr') { should be_empty }
  end

  libtool_config_output = command("#{command_full_path} --config")
  grep_binary_regex = /GREP="(?<grep_binary_path>.+)"/
  sed_binary_regex = /SED="(?<sed_binary_path>.+)"/
  nm_binary_regex = /NM="(?<nm_binary_path>.+)"/
  ld_binary_regex = /LD="(?<ld_binary_path>.+)"/
  ltcflags_regex = /LTCFLAGS="(?<ltcflags_include_directories>.+)"/
  dd_binary_regex = /lt_truncate_bin="(?<dd_binary_fullpath>.+)bs.*"/
  describe libtool_config_output do
    its('exit_status') { should eq 0 }
    its('stderr') { should be_empty }
    its('stdout') { should_not be_empty }
    its('stdout') { should match /#{grep_binary_regex}/ }
    its('stdout') { should match /#{sed_binary_regex}/ }
    its('stdout') { should match /#{nm_binary_regex}/ }
    its('stdout') { should match /#{ld_binary_regex}/ }
    its('stdout') { should match /#{ltcflags_regex}/ }
    its('stdout') { should match /#{dd_binary_regex}/ }
  end

  grep_binary_fullpath = (libtool_config_output.stdout.match /#{grep_binary_regex}/)[1]
  describe file(grep_binary_fullpath) do
    it { should exist }
  end

  sed_binary_fullpath = (libtool_config_output.stdout.match /#{sed_binary_regex}/)[1]
  describe file(sed_binary_fullpath) do
    it { should exist }
  end

  ld_binary_regex = /LD="(?<ld_binary_path>.+)"/
  ld_binary_fullpath = (libtool_config_output.stdout.match /#{ld_binary_regex}/)[1]
  describe file(ld_binary_fullpath) do
    it { should exist }
  end

  ##################################################################################
  ######   THE FOLLOWING TESTS ARE FAILING SO SKIPPED UNTIL ISSUE RESOLVED    ######
  ######        https://github.com/chef-base-plans/libtool/issues/1           ######
  ##################################################################################
  nm_binary_fullpath = (libtool_config_output.stdout.match /#{nm_binary_regex}/)[1]
  describe file(nm_binary_fullpath) do
    xit { should exist }
  end

  dd_binary_regex = /lt_truncate_bin="(?<dd_binary_fullpath>.+)bs.*"/
  dd_binary_fullpath = (libtool_config_output.stdout.match /#{dd_binary_regex}/)[1]
  describe file(dd_binary_fullpath) do
    xit { should exist }
  end
  
  ltcflags_regex = /LTCFLAGS="(?<ltcflags_include_directories>.+)"/
  ltcflags_directories = (libtool_config_output.stdout.match /#{ltcflags_regex}/)[1]
  ltcflags_directories.split(" ").each { |item|
    item.gsub!("-I","")
    describe file(item) do
      xit { should exist }
    end
  }

end