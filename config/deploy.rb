##
# Resources
# => http://github.com/guides/deploying-with-capistrano
# => http://peepcode.com/products/capistrano-2
##

#############################################################
#	Settings
#############################################################

default_run_options[:pty] = true
set :use_sudo, true
set :ssh_options, { :forward_agent => true }
set :domain, "bigquiz.info"

set :user, "deploy"
set :runner, user ## required in current version of capistrano
set :domain, "bigquiz.info"
set :scm, :git 
## set :scm_passphrase, "p00p" #This is your custom users password
#default_environment["TZ"] = "UTC"
## set :default_environment, { "TZ" => "UTC" }

#############################################################
#	Application
#############################################################
set :application, "find_a_store"
set :deploy_to, "/home/#{user}/#{application}"

set :repository,  "git://github.com/captproton/find-a-store.git"
set :branch, "mapping"
set :rails_env, "production"
set :mysql_socket, "/var/run/mysqld/mysqld.sock"


# =============================================================================
# RAILS VERSION
# =============================================================================
# Use this to freeze your deployment to a specific rails version.  Uses the rake
# init task run in after_symlink below.

set :rails_version, 8430 # used by the custom deploy_edge rake task


# TODO: test this works and I can remove the restart task and use the cleanup task
# set :use_sudo, false

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :app, domain
role :web, domain
role :db,  domain, :primary => true


# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
# set :gateway, "gate.host.com"  # default to no gateway

# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

# no sudo access on txd :)

# ** Nota Bene:     Because Capistrano 2 can use plugins, most tasks will be run in the plugin
#                   See:  http://peepcode.com/products/capistrano-2

desc "Freezes rails version ##{rails_version}"
task :after_symlink do
  run <<-CMD
    cd #{current_release} &&
    rake rails:freeze:edge TAG=#{rails_version}
    
  CMD
end