
class Capistrano::Configuration

  ##
  # Print an informative message with asterisks.

  def inform(message)
    puts "#{'*' * (message.length + 4)}"
    puts "* #{message} *"
    puts "#{'*' * (message.length + 4)}"
  end

  ##
  # Read a file and evaluate it as an ERB template.
  # Path is relative to this file's directory.

  def render_erb_template(filename)
    template = File.read(filename)
    result   = ERB.new(template).result(binding)
  end

  ##
  # Run a command and return the result as a string.
  #
  # TODO May not work properly on multiple servers.

  def run_and_return(cmd)
    output = []
    run cmd do |ch, st, data|
      output << data
    end
    return output.to_s
  end

end

###
# From http://shanesbrain.net/2007/5/30/managing-database-yml-with-capistrano-2-0
##

require 'erb'

before "deploy:setup", :db
after "deploy:update_code", "db:symlink"

namespace :db do
  desc "Create database yaml in shared path"
  task :default do
    db_config = ERB.new <<-EOF
    base: &base
      adapter: mysql
      username: #{user}
      password: #{password}

    development:
      database: #{application}_dev
      socket: /tmp/mysql.sock
      <<: *base

    test:
      database: #{application}_test
      socket: /tmp/mysql.sock
      <<: *base

    production:
      database: #{application}_prod
      socket:   /var/run/mysqld/mysqld.sock
      <<: *base
    EOF

    run "mkdir -p #{shared_path}/config"
    put db_config.result, "#{shared_path}/config/database.yml"
  end

  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

###
#  Resource for slicehost namespace:  http://www.viget.com/extend/building-an-environment-from-scratch-with-capistrano-2/
###
namespace :slicehost do
  desc "Setup Environment"
  task :setup_env do
    update_apt_get
    install_dev_tools
    install_git
    install_sqlite3
    install_zip_unzip
    ## install_mysql  # This does not work remotely.  As is, you need to ssh in to enter mysql root password.
    install_rails_stack
    install_apache
    install_passenger
    config_passenger
    config_vhost
  end

  desc "Update apt-get sources"
  task :update_apt_get do
    sudo "apt-get update"
  end

  desc "Install Development Tools"
  task :install_dev_tools do
    sudo "apt-get install build-essential -y"
  end

  desc "Install Git"
  task :install_git do
    sudo "apt-get install git-core git-svn -y"
  end

  desc "Install Subversion"
  task :install_subversion do
    sudo "apt-get install subversion -y"
  end

  desc "Install MySQL"
  task :install_mysql do
      
    puts "Checking that MySQL is installed..."  
    run "test -x '/usr/bin/mysqladmin'"
    sudo "apt-get install mysql-server libmysql-ruby -y"
  end

  desc "Install PostgreSQL"
  task :install_postgres do
    sudo "apt-get install postgresql libpgsql-ruby -y"
  end

  desc "Install SQLite3"
  task :install_sqlite3 do
    sudo "apt-get install sqlite3 libsqlite3-ruby -y"
  end

  desc "Install zip unzip"
  task :install_zip_unzip do
    sudo "apt-get install zip unzip"
  end

  desc "Install Ruby, Gems, and Rails"
  task :install_rails_stack do
    [
      "sudo apt-get install ruby ruby1.8-dev irb ri rdoc libopenssl-ruby1.8 -y",
      "mkdir -p src",
      "cd src",
      "wget http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz",
      "tar xvzf rubygems-1.0.1.tgz",
      "cd rubygems-1.0.1/ && sudo ruby setup.rb",
      "sudo ln -s /usr/bin/gem1.8 /usr/bin/gem",
      "sudo gem install rails --no-ri --no-rdoc"
    ].each {|cmd| run cmd}
  end

  desc "Install Apache"
  task :install_apache do
    sudo "apt-get install apache2 apache2.2-common apache2-mpm-prefork 
          apache2-utils libexpat1 apache2-prefork-dev libapr1-dev -y"
    sudo "chown :sudo /var/www"
    sudo "chmod g+w /var/www"
  end

  desc "Install Passenger"
  task :install_passenger do
    run "sudo gem install passenger --no-ri --no-rdoc"
    input = ''
    run "sudo passenger-install-apache2-module" do |ch,stream,out|
      next if out.chomp == input.chomp || out.chomp == ''
      print out
      ch.send_data(input = $stdin.gets) if out =~ /(Enter|ENTER)/
    end
  end

  desc "Configure Passenger"
  task :config_passenger do
    passenger_config =<<-EOF
    LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-1.0.5/ext/apache2/mod_passenger.so
    RailsSpawnServer /usr/lib/ruby/gems/1.8/gems/passenger-1.0.5/bin/passenger-spawn-server
    RailsRuby /usr/bin/ruby1.8    EOF
    put passenger_config, "src/passenger"
    sudo "mv src/passenger /etc/apache2/conf.d/passenger"
  end

  desc "Configure VHost"
  task :config_vhost do
    vhost_config =<<-EOF
<VirtualHost *:80>
  ServerName bigquiz.info
  DocumentRoot #{deploy_to}/current/public
</VirtualHost>
    EOF
    put vhost_config, "src/vhost_config"
    sudo "mv src/vhost_config /etc/apache2/sites-available/#{application}"
    sudo "a2ensite #{application}"
  end

  desc "Reload Apache"
  task :apache_reload do
    sudo "/etc/init.d/apache2 reload"
  end
end

namespace :mephisto do
    desc "Creates the shared themes and assets directories"
    task :create_shared_dirs, :roles => [:app] do
        %w(themes assets).each do |dirname|
            run "umask 02 && mkdir -p #{shared_path}/#{dirname}"
        end
        
      ## dirs = %w(themes assets)
      ## run "umask 02 && mkdir #{shared_path}/{#{dirs.join(',')}}"

      upload_default_theme
    end
    desc  "Uploads default theme: usually simpla"
    task :upload_default_theme, :roles => [:app] do
        inform "Old version used to tarball and upload default theme"
        
    end

    after 'deploy:setup', "mephisto:create_shared_dirs"

    desc "Symlinks shared configuration and directories into the latest release"
    task :symlink_shared, :roles => [:app, :db] do
      run "rm -rf #{latest_release}/themes; ln -s #{shared_path}/themes #{latest_release}/themes"
      run "rm -rf #{latest_release}/public/assets; ln -s #{shared_path}/assets #{latest_release}/public/assets"
    end

    desc "Bootstraps the database"
    task :bootstrap_db, :roles => [:db] do
      rails_env = fetch(:rails_env, "production")
      run "cd #{latest_release}; rake RAILS_ENV=#{rails_env} db:bootstrap"
    end
    
end
##
# Custom installation tasks for Ubuntu (Slicehost).
#
# Author: Geoffrey Grosenbach http://topfunky.com
#         November 2007
# Mangled by Carl Tanner June 2008

namespace :peepcode do

  desc "Copy config files"
  task :copy_config_files do
    run "cp #{shared_path}/config/* #{release_path}/config/"
  end
  ## after "deploy:update_code", "peepcode:copy_config_files" ## commented out for now because of db namespace
  


  desc "Create shared/config directory and default database.yml."
  task :create_shared_config do
    run "mkdir -p #{shared_path}/config"

    # Copy database.yml if it doesn't exist.
    result = run_and_return "ls #{shared_path}/config"
    unless result.match(/database\.yml/)
      inform "Please review database.yml in the shared directory to ensure proper settings."
    end
  end
  ## after "deploy:setup", "peepcode:create_shared_config" ## commented out for now because of db namespace

  
  namespace :install do

    desc "Install server software"
    task :default do
      setup

      # TODO
      # * Uninstall httpd: chkconfig --del httpd

      ##git
      ##memcached
      ##munin
      ##httperf
      ##emacs
      ##tree
      special_gems
      set_time_to_utc
    end

    task :setup do
      sudo "rm -rf src"
      run  "mkdir -p src"
    end

    desc "Install git"
    task :git do
      curl
      cmd = [
        "cd src",
        "wget http://kernel.org/pub/software/scm/git/git-1.5.3.5.tar.gz",
        "tar xfz git-1.5.3.5.tar.gz",
        "cd git-1.5.3.5",
        "make prefix=/usr/local all",
        "sudo make prefix=/usr/local install"
      ].join(" && ")
      run cmd
    end

    desc "Install curl"
    task :curl do
      sudo "yum install curl curl-devel -y"
    end

    desc "Install memcached"
    task :memcached do
      # TODO Needs to run ldconfig after libevent is installed
      run "echo '/usr/local/lib' > ~/src/memcached-i386.conf"
      sudo "mv ~/src/memcached-i386.conf /etc/ld.so.conf.d/memcached-i386.conf"
      sudo "/sbin/ldconfig"

      result = File.read(File.dirname(__FILE__) + "/templates/install-memcached-linux.sh")
      put result, "src/install-memcached-linux.sh"

      cmd = [
        "cd src",
        "sudo sh install-memcached-linux.sh"
      ].join(" && ")
      run cmd
    end

    desc "Install emacs"
    task :emacs do
      sudo "yum install emacs -y"
    end

    desc "Install gems needed by PeepCode and Mephisto"
    task :special_gems do
      # TODO hpricot
      %w(libxml-ruby gruff sparklines ar_mailer bong production_log_analyzer rspec tzinfo).each do |gemname|
        sudo "gem install #{gemname} -y"
      end
    end

    desc "Install munin"
    task :munin do
      sudo "rpm -Uhv http://apt.sw.be/packages/rpmforge-release/rpmforge-release-0.3.6-1.el4.rf.i386.rpm"
      sudo "yum install munin munin-node -y"
      post_munin
      munin_plugins
    end

    desc "Post-Munin Tasks"
    task :post_munin do
      cmds = [
        "rm -rf /var/www/munin",
        "mkdir -p /var/www/html/munin",
        "chown munin:munin /var/www/html/munin",
        "/sbin/service munin-node restart"
      ]
      cmds.each do |cmd|
        sudo cmd
      end

      inform "You must link /var/www/html/munin to a web-accessible location."
    end

    desc "Upload and configure desired plugins for munin."
    task :munin_plugins do
      # Reset
      sudo "rm -f /etc/munin/plugins/*"

      # Upload
      put File.read(File.dirname(__FILE__) + "/templates/memcached_"), "/tmp/memcached_"
      sudo "cp /tmp/memcached_ /usr/share/munin/plugins/memcached_"
      sudo "chmod 755 /usr/share/munin/plugins/memcached_"

      # Configure
      {
        "cpu" => "cpu",
        "df" => "df",
        "fw_packets" => "fw_packets",
        "if_eth0" => "if_",
        "if_eth1" => "if_",
        "load" => "load",
        "memory" => "memory",
        "mysql_bytes" => "mysql_bytes",
        "mysql_queries" => "mysql_queries",
        "mysql_slowqueries" => "mysql_slowqueries",
        "mysql_threads" => "mysql_threads",
        "netstat" => "netstat",
        "ping_nubyonrails.com" => "ping_",
        "ping_peepcode.com" => "ping_",
        "ping_staging.topfunky.railsmachina.com" => "ping_",
        "ping_rubyonrailsworkshops.com" => "ping_",
        "ping_theonlineceo.com" => "ping_",
        "ping_topfunky.com" => "ping_",
        "processes" => "processes",
        "swap" => "swap",
        "users" => "users",
      }.each do |name, source|
        sudo "ln -s /usr/share/munin/plugins/#{source} /etc/munin/plugins/#{name}"
      end
      sudo "/sbin/service munin-node restart"
      sudo "-u munin munin-cron"

      inform "You must may need to run: sudo cpan Cache::Memcached"
    end

    desc "Install command-line directory lister"
    task :tree do
      cmd = [
        "cd src",
        "wget ftp://mama.indstate.edu/linux/tree/tree-1.5.1.1.tgz",
        "tar xfz tree-1.5.1.1.tgz",
        "cd tree-1.5.1.1",
        "make",
        "sudo make install"
      ].join(' && ')
      run cmd
    end

    desc "Set time to UTC"
    task :set_time_to_utc do
      sudo "ln -nfs /usr/share/zoneinfo/UTC /etc/localtime"
    end

    desc "Install newer version of make"
    task :make do
      cmd = [
        "cd src",
        "wget http://ftp.gnu.org/pub/gnu/make/make-3.81.tar.gz",
        "tar xfz make-3.81.tar.gz",
        "cd make-3.81",
        "./configure --prefix=/usr/local",
        "make",
        "sudo make install"
      ].join(" && ")
      run cmd
    end


    desc "Install beanstalk in-memory queue"
    task :beanstalk do
      # TODO Bail unless make 3.81 is installed
      cmd = [
        "cd src",
        "git clone http://xph.us/src/beanstalkd.git",
        "cd beanstalkd",
        "/usr/local/bin/make"
      ].join(" && ")
      # TODO Install it somewhere
      run cmd
    end

  end

end
