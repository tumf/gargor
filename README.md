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

`gargor`の設定情報は、内部DSLによりに以下のように記述します。

```ruby
# 世代数: 1以上を指定してください
max_generations 10

# 個体数: 1世代あたりの個体数
population 10

# エリート: 世代交代の時に適応値の高い個体をそのまま次世代に引き継ぐ数
elite 1

# 突然変異の確率: "0.01"で"1%"
mutation 0.01

# ターゲットをChefで料理するコマンド %sには、ノード名が入る
target_cooking_cmd "knife solo cook %s"

# ターゲットのノード
#   攻撃前に以下のノードすべてに対してtarget_cooking_cmdが実施される
target_nodes ["www-1.example","www-2.example","db-1.example"]

# 攻撃コマンド
attack_cmd "ssh attacker.example ./bin/ghakai www-1.example.yml 2>/dev/null"


# 攻撃結果の評価
# code: attack_cmdのプロセス終了コード(普通は0:成功)
# out:  attack_cmdの標準出力
# time: attack_cmdの実行時間
evaluate do |code,out,time|
  puts out
  fitness = 0

  # 攻撃コマンドで使っている、グリーン破壊の標準出力から
  # FAILEDの値を抜き出し0以外は適応値0としている
  if time > 0 && code == 0 && /^FAILED (\d+)/ =~ out && $1 == "0"
    # 攻撃コマンドで使っている、グリーン破壊の標準出力から
    # 適応値に代用できそうなものを正規表現で取得する
    # request count:200, concurrenry:20, 45.060816 req/s
    if /, ([\.\d]+) req\/s/ =~ out
      fitness = $1.to_f
    end
    # 単純に実行時間で適応値を設定したいなら以下のようにしても良い
    # fitness = 1/time
  end
  # このブロックは必ず適応値を返すこと(整数or浮動小数)
  fitness
end

# パラメータ定義
# GAにより変動されるパラメータをここで定義する
# 
# param 名前 do
# json_file: 値を上書くJSONファイル nodes/*.jsonやroles/*.json
#            (注意!) gargorはこのjsonファイルを容赦なく書き換える
# json_path: json_fileの中から書変える値の場所をJSONPath形式で指定する
# mutaion:   突然変異時の値の設定
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

このDSLファイルは任意のファイル名でChefのリポジトリに含めてしまうことを推奨します。`dsl-file`を省略した場合は、カレントディレクトリの`gargor.rb`を探します。

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

負荷試験の厳しさによって個体が全滅することがあります。すると以下のように表示され、プログラムが終了します。

    ***** EXTERMINATION ******
    
これは、個体の環境が厳しすぎるためで負荷の条件を緩めて再度実施してください。    

## FAQ

#####  `gargor`はなんて読むの?

「がるごる」

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
