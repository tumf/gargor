# -*- coding: utf-8 -*-
# generations: set > 1
max_generations 10

# individuals number of some generation.
population 10

# elite number of some generation.(carried over)
elite 1

# Probability of mutation　set "0.01" to "1%" (when crossover)
mutation 0.01

# target cook command : '%s' will replace by node name.
target_cooking_cmd "knife solo cook %s"

# target nodes
#   performing target_cooking_command before the attack.
target_nodes ["www-1.example","www-2.example","db-1.example"]

# attack command
attack_cmd "ssh attacker.example ./bin/ghakai www-1.example.yml 2>/dev/null"


# evalute of the attack
# code: exit code of attack_cmd command (0 => succees)
# out:  standard output of attack_cmd command
# time: execute time of attack_cmd
evaluate do |code,out,time|
  p time
  p code
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
