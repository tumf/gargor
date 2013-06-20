Auto-tuning internet servers by Genetic Algorithm
====================================================

You can get good settings during sleeping ;)

First it is necessary to prepare to the point where an ordinary stress test is possible. Please prepare the server to be used for attacking in a location that is close (in terms of network) to the target. Suitable specifications are required for the Attacker as well.

Anything is acceptable as a stress tool providing that it can be used from a command line. Although `ab(Apache Bench)` etc. have been included from the beginning and therefore would be simple, this time, a software called [green-hakai](https://github.com/KLab/green-hakai) was used. (The installation instructions for `green-hakai` are available from the product’s website)

When performing automatic tuning, the target (= sever group of the tuning target) is controlled by Chef and it is necessary that the parameters become attributes of Chef. For example, when the template `httpd.conf.erb` of `httpd.conf` becomes as shown: 

```
<IfModule prefork.c>
StartServers     8
MinSpareServers  10
MaxSpareServers  20
ServerLimit      255
MaxClients       255
MaxRequestsPerChild  1000
</IfModule>
```

If these `MaxClients` are to be made attribute of Chef, do it as follows:

```
<IfModule prefork.c>
StartServers     8
MinSpareServers  10
MaxSpareServers  20
ServerLimit      255
MaxClients       <%= node["httpd"]["max_clients"] %>
MaxRequestsPerChild  1000
</IfModule>
```

When in this state, by writing as shown below in `nodes/www-1.example.json`, it is possible to control `MaxClients` of the `www-1.example` server.

```
{
    "httpd" :{
        "max_clients" :255
    },
    ...
}
```

As a result of rewriting this JSON, deploying it to the target by using Chef, and then applying the stress test, it will be `gargor` (the new software) that searches the new test parameter using GA. 

Install `gargor` by doing the following: (Ruby 1.9.3 or higher is required) 

```
[sudo] gem install gargor
```

Position `gargor.rb` under the Chef repository. Rewrite the contents as necessary.

```ruby
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


When using something other than `green-hakai`, it will be necessary to customize `evaluate` block.


```
# fitness = 1/time
```

However, by removing the comment out of this part, it is possible to decide a rough score by the (inverse number of) the measurement time.

`gargor` performs the stress test for the number of (number of generations * number of individuals) at the maximum and searches for parameters that appear good. As it takes a long time, it is probably best to run when finishing work for the day in order to confirm the results the next morning.

Of course, it is possible to perform multiple settings for parameters.

As GA is used, there are erratic elements, and unless the software is tried, it is unknown whether good results will be output. If the number of individuals and the number of generations are increased, it will take longer but the precision will be improved. Also, because the precision also changes depending on how `mutation` is written, the user is encouraged to try many things.

As `gargor` is only just-created software, please report bugs and fixes to `github`. Developer is waiting for pull-request.

> https://github.com/tumf/gargor
