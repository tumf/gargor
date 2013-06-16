# gargor

`gargor`はChefで管理されたサーバのパラメータと負荷試験結果を遺伝的アルゴリズム(genetic algorithm)により機械学習し、最適値を探索します。本ソフトウェアをうまく使うことで今まで勘と経験に頼っていたサーバチューニングをより最適にかつ自動化することができます。

## インストール

Ruby 1.9以降が必要です

    $ gem install gargor
    
## どのように動くのか

1. 現在のChefの設定ファイル(JSON)から個体を一つ作ります。
2. 残りの個体を突然変異により作ります。
3. 各個体に対し負荷試験(Chefによる配備→攻撃)を実施し、適応値を算出します。
4. 現世代の個体群に対して、エリートと残りを交叉および突然変異により次世代の個体群をつくります。
5. 次世代の個体群を現世代として`3.`に戻ります。これを指定した世代分実施します。
6. 最後に最も高い適応値の個体をサーバに配備して終了します

## 使い方

    $ gargor [dsl-file]

`dsl-file`を省略した場合は、カレントディレクトリの`gargor.rb`を探します。`dsl-file`の書き方は、添付の`doc/sample.rb`を御覧ください
    

### 注意

`gargor`は、DSLファイルで指定されたChefのJSONを直接（問答無用で）書き換えます。`git stash`を使うなりしてオリジナルが消えないように配慮ください。

## サンプルレシピ

`Chef`のサンプルレシピをTipsを交えてご紹介します。

### mysql


```ruby
# この時点で起動しようとすると以前の設定ファイルがおかしい場合にエラーが出てしまう
service "mysqld" do
  action :nothing
end

template "/etc/my.cnf" do
  source "www/my.cnf.erb"
  notifies :restart,"service[mysqld]"
end

# ib_logfile0,1はib_logfile1はinnodb_log_file_sizeを変えるとエラーになるので毎回消す
file "/var/lib/mysql/ib_logfile0" do
  action :delete
  notifies :restart,"service[mysqld]"
end
file "/var/lib/mysql/ib_logfile1" do
  action :delete
  notifies :restart,"service[mysqld]"
end
```

このテンプレートは以下のようになっています。`innodb_buffer_pool_size`を探索対象のパラメータにしたいのですが、「`innodb_log_file_size`を`innodb_buffer_pool_size`の25%にすべし」と注意書きがあるので、`innodb_log_file_size`を設定対象にして、`innodb_buffer_pool_size`をその4倍にしています。

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

Apacheのパフォーマンスチューニングでは以下の様にしています。レシピには全く工夫はありません。

```
service "httpd" do
  action :nothing
end

template "/etc/httpd/conf/httpd.conf" do
  source "www/httpd.conf.erb"
  notifies :restart,"service[httpd]"
end
```

ポイントは`MinSpareServers`と`MaxSpareServers`のように上下関係のあるパラメータの決定方法を以下のように`min_spare_servers`と`range_spare_servers`としている点です。また、`ServerLimit`=`MaxClients`としています。

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

## 負荷試験ツール

コマンドラインで使えるものであれば、大体使うことができます。サンプルでは、[グリーン破壊](https://github.com/KLab/green-hakai/)を使わせて頂きました。

負荷試験の厳しさによって個体が死滅することがあります。すると以下のように表示され、プログラムが終了します。

    ***** EXTERMINATION ******
    
これは、個体の環境が厳しすぎるためで負荷試験を緩めて再度実施してください。    

## FAQ

#####  `gargor`はなんて読むの?

「がるごる」

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
