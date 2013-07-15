# gargor [![Build Status](https://travis-ci.org/tumf/gargor.png?branch=master)](https://travis-ci.org/tumf/gargor) [![Gem Version](https://badge.fury.io/rb/gargor.png)](http://badge.fury.io/rb/gargor) [![Code Climate](https://codeclimate.com/github/tumf/gargor.png)](https://codeclimate.com/github/tumf/gargor) [![Dependency Status](https://gemnasium.com/tumf/gargor.png)](https://gemnasium.com/tumf/gargor) [![Coverage Status](https://coveralls.io/repos/tumf/gargor/badge.png)](https://coveralls.io/r/tumf/gargor)

`gargor` is software which uses genetic algorithm to support parameter tuning of the servers controlled by Chef.Using this software, you are able to optimize and automate the server tuning, which you did until now based on a combination of my experience and intuition. 　

## Install

Ruby 1.9-

    $ [sudo] gem install gargor
    
## How it works

1. Create a individual from current Chef settings (JSON file).
2. Create remaining individuals by mutation.
3. By performing stress-test (deloy by Chef and Attack by some stress tool) for each individuals to evaluate fitness.
4. To create Individuals of Next-generation, Individuals of current generation are crossovered or mutated each other.
5. Treat individuals of Next-generation as current generation. return to 3. Repeat until the max generations number of times.
6. It ends with a deployment to the server with a individual which has the highest fitness.

## Usage

    $ gargor [options] tune [dsl-file]

The dsl-file of `gargor` should be written as belows:

```ruby
# generations: set > 1
max_generations 10

# individuals number of some generation.
population 10

# elite number of some generation.(carried over)
elite 1

# Probability of mutation　set "0.01" (is 1%)
mutation 0.01

# target cook command : '%s' will replace by node name.
target_cooking_cmd "knife solo cook %s"

# target nodes
#   performing target_cooking_command before the attack.
target_nodes ["www-1.example","www-2.example","db-1.example"]

# attack command
attack_cmd "ssh attacker.example ./bin/ghakai www-1.example.yml 2>/dev/null"

# logger
logger "gargor.log"

# state
state ".gargor.state"

# or optional settings like belows:
# 
# logger "gargor.log" do |log|
#   log.level = Logger::INFO
# end

# evalute of the attack
# code: exit code of attack_cmd command (0 => succees)
# out:  standard output of attack_cmd command
# time: execute time of attack_cmd
evaluate do |code,out,time|
  puts out
  fitness = 0
  # get "FAILED" count from stadard output of stress-tool,
  # and set fitess to 0 when FAILED > 0.
  if time > 0 && code == 0 && /^FAILED (\d+)/ =~ out && $1 == "0"
    # get fitness from stadard output of stress-tool.
    # e.g.: request count:200, concurrenry:20, 45.060816 req/s
    if /, ([\.\d]+) req\/s/ =~ out
      fitness = $1.to_f
    end
    # To get fitness simply,to use execution time
    # fitness = 1/time
  end
  # This block must return the fitness.(integer or float)
  fitness
end

# definition of parameters(GA)
#
# param _name_ do
# json_file: Chef parameter(JSON) file (such as  nodes/*.json or roles/*.json)
#            (Warning!) gargor will overwrite their json files.
# json_path: to locate the value by JSONPath
# mutaion:   to set value when mutaion
param "max_clients" do
  json_file "roles/www.json"
  json_path '$.httpd.max_clients'
  mutation rand(500)+10
end

param "innodb_log_file_size" do
  json_file "nodes/db-1.example.json"
  json_path '$.mysqld.innodb_log_file_size'
  mutation rand(200)
end

param "sort_buffer_size" do
  json_file "nodes/db-1.example.json"
  json_path '$.mysqld.sort_buffer_size'
  mutation rand(1000)
end

param "read_buffer_size" do
  json_file "nodes/db-1.example.json"
  json_path '$.mysqld.read_buffer_size'
  mutation rand(1000)
end

param "query_cache_size" do
  json_file "nodes/db-1.example.json"
  json_path '$.mysqld.query_cache_size'
  mutation rand(100)
end
```

### Warning

The `gargor` will overwrite Chef JSON files.So you should take care of original files.

## Sample Chef recipe

### mysql


```ruby
service "mysqld" do
  action :nothing
end

template "/etc/my.cnf" do
  source "www/my.cnf.erb"
  notifies :restart,"service[mysqld]"
end

file "/var/lib/mysql/ib_logfile0" do
  action :delete
  notifies :restart,"service[mysqld]"
end
file "/var/lib/mysql/ib_logfile1" do
  action :delete
  notifies :restart,"service[mysqld]"
end
```

my.conf.erb

```
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
# Default to using old password format for compatibility with mysql 3.x
# clients (those using the mysqlclient10 compatibility package).
old_passwords=1

# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
# symbolic-links=0

skip-locking
query_cache_size = <%= node["mysqld"]["query_cache_size"] %>M
key_buffer = <%= node["mysqld"]["key_buffer"] %>K
max_allowed_packet = <%= node["mysqld"]["max_allowed_packet"] %>M
table_cache = <%= node["mysqld"]["table_cache"] %>
sort_buffer_size = <%= node["mysqld"]["sort_buffer_size"] %>K
read_buffer_size = <%= node["mysqld"]["read_buffer_size"] %>K
read_rnd_buffer_size = <%= node["mysqld"]["read_rnd_buffer_size"] %>K
net_buffer_length = <%= node["mysqld"]["net_buffer_length"] %>K
thread_stack = <%= node["mysqld"]["thread_stack"] %>K

skip-networking
server-id	= 1

# Uncomment the following if you want to log updates
#log-bin=mysql-bin

# Disable Federated by default
skip-federated

# Uncomment the following if you are NOT using BDB tables
#skip-bdb

# Uncomment the following if you are using InnoDB tables
innodb_data_home_dir = /var/lib/mysql/
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /var/lib/mysql/
innodb_log_arch_dir = /var/lib/mysql/
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
innodb_buffer_pool_size = <%= node["mysqld"]["innodb_log_file_size"]*4 %>M
innodb_additional_mem_pool_size = <%= node["mysqld"]["innodb_additional_mem_pool_size"] %>M
# Set .._log_file_size to 25 % of buffer pool size
innodb_log_file_size = <%= node["mysqld"]["innodb_log_file_size"] %>M
innodb_log_buffer_size = <%= node["mysqld"]["innodb_log_buffer_size"] %>M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

### httpd

When I tune Apache httpd servers ,The Chef recipe is as below:

```
service "httpd" do
  action :nothing
end

template "/etc/httpd/conf/httpd.conf" do
  source "www/httpd.conf.erb"
  notifies :restart,"service[httpd]"
end
```

httpd.conf.erb

```
<IfModule prefork.c>
StartServers     <%= node["httpd"]["start_servers"] %>
MinSpareServers  <%= node["httpd"]["min_spare_servers"] %>
MaxSpareServers  <%= node["httpd"]["min_spare_servers"] + node["httpd"]["range_spare_servers"] %>
ServerLimit      <%= node["httpd"]["max_clients"] %>
MaxClients       <%= node["httpd"]["max_clients"] %>
MaxRequestsPerChild  <%= node["httpd"]["max_request_per_child"] %>
</IfModule>
```

## Stress Tools

I use [green hakai](https://github.com/KLab/green-hakai/).

You can use ab(Apache bench) and so on.

## Continuous Performance Tuning

After v1.0, `gargor` can save last status of the individuals to file (which indicates `state` in DSL or `--state=FILE` option).
You can excecute `gargor` by the daily cron, your servers will be tuned continuouslly.

```
0 4 * * * cd /path/to/project && gargor --state=.gargor.status
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


