#
# Cookbook Name:: yourls-cookbook
# Recipe:: default
#
# The MIT License (MIT)
#
# Copyright (c) 2016 Yorgos Saslis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

secrets = data_bag_item('yourls', 'secrets')

# Download and extract yourls source
ark 'yourls' do
  url node['yourls']['url']
  path node['yourls']['path']
  owner node['apache']['user']
  action :put
  not_if { ::File.exists?("#{node['yourls']['path']}/yourls") }
end

template "#{node['yourls']['path']}/yourls/user/config.php" do
  source 'yourls_config.php.erb'
  variables({
    :db_name => 'yourls',
    :db_host => node['yourls']['db_host'],
    :db_pass => secrets['db_pass'],
    :yourls_url => node['yourls']['yourls_url'],
    :gmt_offset => node['yourls']['gmt_offset'],
    :usernames_passwords => {
      'sysadmin' => secrets['sysadmin_pass']
    }
  })
  owner node['apache']['user']
  group node['apache']['group']
end

file "#{node['yourls']['path']}/yourls/.htaccess" do
  content 'FallBackResource yourls-loader.php'
  mode '0755'
  owner node['apache']['user']
  group node['apache']['group']
end

web_app 'yourls' do
  template 'yourls_apache_conf.erb'
  server_name node['yourls']['server_name]
  server_port node['yourls']['port']
  document_root node['yourls']['document_root']
  apache_listen node['yourls']['port']
  directory_index 'index.php'
  allow_override 'All'
  notifies :restart, 'service[apache2]'
end
