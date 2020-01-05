# Kiosk recipe - all configs in one file compatible with chef-apply

# Update components
execute "yum update -y"

# Install x11 and xcalc
execute "which xinit || yum install -y 'xorg*'"
package 'epel-release'
package 'xcalc'

# Configure xcalc as the only app working on the console
execute 'grep xcalc /etc/profile.d/kiosk.sh || echo -e "tty | grep tty1 >/dev/null && { xinit /usr/bin/xcalc $* -- >/dev/null 2>/dev/null ; logout ; }" > /etc/profile.d/kiosk.sh'

# Configure 2FA for operators
package 'google-authenticator'
ruby_block 'Add google auth to /etc/pam.d/login' do
  block do
    file = Chef::Util::FileEdit.new("/etc/pam.d/login")
    file.insert_line_after_match("auth       substack     system-auth", "auth       required     pam_google_authenticator.so nullok")
    file.write_file 
  end
  not_if 'grep pam_google_authenticator.so /etc/pam.d/login'
end

file '/etc/google-authenticator-template' do
  content <<-EOH
BJL5RZU3ZIINLHAKX2HIJ5LVIF
" RATE_LIMIT 3 30 1578092127
" WINDOW_SIZE 17
" DISALLOW_REUSE 52603063 52603070
" TOTP_AUTH
48694525
93774841
63530385
92533497
99031477
EOH
  mode '0400'
  owner 'root'
  group 'root'
end

# Pre-provision operators with their password hashes and Google-auth activation keys
# For the test purposes, all passwords are "vagrant"
node.default['users'] = {
  'vagrant' => {
    'passwordhash' => '$6$vw5Vl0yK7Lf1EURo$y0U88XxyPG7jsPxVLS.uAWmC3OZa25uWJZje8r8dM11JfRB.GQvdBryKldHNITowAj7p0TNTyIoyAMrX9qw9n0',
    'mfakey' => 'BJL5RZU3ZIINLHAKX2HIJ5LVIE' 
  },
  'nadav' => {
    'passwordhash' => '$6$vw5Vl0yK7Lf1EURo$y0U88XxyPG7jsPxVLS.uAWmC3OZa25uWJZje8r8dM11JfRB.GQvdBryKldHNITowAj7p0TNTyIoyAMrX9qw9n0',
    'mfakey' => 'BJL5RZU3ZIINLHAKX2HIJ5LVIE' 
  }
}

node['users'].each do |userobj|
  username = "#{userobj[0]}" 
  homedir = "/home/#{userobj[0]}"
  passhash = node['users']["#{userobj[0]}"]['passwordhash']
  googlekey = node['users']["#{userobj[0]}"]['mfakey']


  group username  
  user username do 
    gid username
    home homedir
    shell '/bin/bash'
    password passhash
  end

  directory homedir do
    owner username
    group username
    mode '0700'
  end

  execute "Create/update google-authenticator user config file" do
    command "cat /etc/google-authenticator-template | sed 's~BJL5RZU3ZIINLHAKX2HIJ5LVIF~#{googlekey}~' > #{homedir}/.google_authenticator ; chown #{username}:#{username} #{homedir}/.google_authenticator ; chmod 400 #{homedir}/.google_authenticator "
    not_if "grep #{googlekey} #{homedir}/.google_authenticator"
  end

end
