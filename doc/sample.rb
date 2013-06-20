# -*- coding: utf-8 -*-
# Gargor Sample DSL file

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



