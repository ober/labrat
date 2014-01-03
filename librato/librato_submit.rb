#!/usr/bin/env ruby
require 'librato/metrics'
require 'yaml'
require 'json'
require 'pp'

@config = YAML::load(File.read("#{ENV['HOME']}/.librato.yml"))
Librato::Metrics.authenticate @config['email'], @config['api_token']

def process_json(pattern,&block)
  Dir.glob("./*#{pattern}.json") do |json|
    begin
      data = JSON.parse(File.read(json))
      name = data['system']['name'] if data and data['system'] and data['system']['name']
      name ||= json.split("-#{pattern}.json").to_s.split("/").last.gsub(/\"/,'').gsub(/\]/,'')
      if data and data['status'] and data['status']['value'] == "OK"
        yield(data,name,json)
      end
    rescue Exception => e
      File.open("/data/ec2read/librato_submit.err", "a+") {|f|
        f.puts "Invalid json. Could not read #{json}: #{e.inspect}"
      }
    end
  end
end

def librato_load
  puts "in #{__method__}"
  process_json("load") { |data,name,json|
    data['data'].each_pair do |k,v|
      @queue.add "load_#{k}" => { :type => :gauge, :value => v, :source => name }
    end
  }
end

def librato_memfree
  puts "in #{__method__}"
  process_json("memfree") { |data,name,json|
    data['data'].each_pair do |k,v|
      @queue.add "memfree_#{k}" => { :type => :gauge, :value => v, :source => name }
    end
  }
end

def librato_netstat
  puts "in #{__method__}"
  process_json("netstat") { |data,name,json|
    data['data'].each_pair do |k,v|
      @queue.add "netstat_#{k}" => { :type => :counter, :value => v, :source => name }
    end
  }
end

def librato_redis
  puts "in #{__method__}"
  process_json("redis") { |data,name,json|
    @queue.add "redis_server_lru_clock" => { :type => :counter, :value => data['data']['server']['lru_clock'].to_f, :source => name } #"=>"834472",
    @queue.add "redis_server_redis_git_dirty" => { :type => :gauge, :value => data['data']['server']['redis_git_dirty'].to_f, :source => name } #"=>"0",
    @queue.add "redis_server_uptime_in_days" => { :type => :gauge, :value => data['data']['server']['uptime_in_days'].to_f, :source => name } #"=>"54",
    @queue.add "redis_server_process_id" => { :type => :gauge, :value => data['data']['server']['process_id'].to_f, :source => name } #"=>"3063",
    @queue.add "redis_server_tcp_port" => { :type => :gauge, :value => data['data']['server']['tcp_port'].to_f, :source => name } #"=>"6379",
    @queue.add "redis_server_uptime_in_seconds" => { :type => :counter, :value => data['data']['server']['uptime_in_seconds'].to_f, :source => name } #"=>"4742360",
    @queue.add "redis_server_arch_bits" => { :type => :gauge, :value => data['data']['server']['arch_bits'].to_f, :source => name } #"=>"64"}
    @queue.add "redis_stats_evicted_keys" => { :type => :counter, :value => data['data']['stats']['evicted_keys'].to_f, :source => name } #"=>"0",
    @queue.add "redis_stats_keyspace_hits" => { :type => :counter, :value => data['data']['stats']['keyspace_hits'].to_f, :source => name } #"=>"35532",
    @queue.add "redis_stats_instantaneous_ops_per_sec" => { :type => :counter, :value => data['data']['stats']['instantaneous_ops_per_sec'].to_f, :source => name } #"=>"0",
    @queue.add "redis_stats_keyspace_misses" => { :type => :counter, :value => data['data']['stats']['keyspace_misses'].to_f, :source => name } #"=>"254250",
    @queue.add "redis_stats_pubsub_channels" => { :type => :counter, :value => data['data']['stats']['pubsub_channels'].to_f, :source => name } #"=>"0",
    @queue.add "redis_stats_latest_fork_usec" => { :type => :counter, :value => data['data']['stats']['latest_fork_usec'].to_f, :source => name } #"=>"722",
    @queue.add "redis_stats_pubsub_patterns" => { :type => :counter, :value => data['data']['stats']['pubsub_patterns'].to_f, :source => name } #"=>"0",
    @queue.add "redis_stats_rejected_connections" => { :type => :counter, :value => data['data']['stats']['rejected_connections'].to_f, :source => name } #"=>"0",
    @queue.add "redis_stats_total_commands_processed" => { :type => :counter, :value => data['data']['stats']['total_commands_processed'].to_f, :source => name } #"=>"497800",
    @queue.add "redis_stats_total_connections_received" => { :type => :counter, :value => data['data']['stats']['total_connections_received'].to_f, :source => name } #"=>"9949",
    @queue.add "redis_stats_expired_keys" => { :type => :counter, :value => data['data']['stats']['expired_keys'].to_f, :source => name } #"=>"133"}
    @queue.add "redis_persistence_rdb_last_bgsave_time_sec" => { :type => :gauge, :value => data['data']['persistence']['rdb_last_bgsave_time_sec'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_aof_enabled" => { :type => :gauge, :value => data['data']['persistence']['aof_enabled'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_rdb_bgsave_in_progress" => { :type => :gauge, :value => data['data']['persistence']['rdb_bgsave_in_progress'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_aof_current_rewrite_time_sec" => { :type => :gauge, :value => data['data']['persistence']['aof_current_rewrite_time_sec'].to_f, :source => name } #"=>"-1",
    @queue.add "redis_persistence_aof_last_rewrite_time_sec" => { :type => :gauge, :value => data['data']['persistence']['aof_last_rewrite_time_sec'].to_f, :source => name } #"=>"-1",
    @queue.add "redis_persistence_aof_rewrite_scheduled" => { :type => :gauge, :value => data['data']['persistence']['aof_rewrite_scheduled'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_aof_rewrite_in_progress" => { :type => :gauge, :value => data['data']['persistence']['aof_rewrite_in_progress'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_rdb_changes_since_last_save" => { :type => :gauge, :value => data['data']['persistence']['rdb_changes_since_last_save'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_loading" => { :type => :gauge, :value => data['data']['persistence']['loading'].to_f, :source => name } #"=>"0",
    @queue.add "redis_persistence_rdb_current_bgsave_time_sec" => { :type => :gauge, :value => data['data']['persistence']['rdb_current_bgsave_time_sec'].to_f, :source => name } #"=>"-1",
    @queue.add "redis_persistence_rdb_last_save_time" => { :type => :counter, :value => data['data']['persistence']['rdb_last_save_time'].to_f, :source => name } #"=>"1371492071"}
    @queue.add "redis_memory_used_memory_lua" => { :type => :gauge, :value => data['data']['memory']['used_memory_lua'].to_f, :source => name } #"=>"31744",
    @queue.add "redis_memory_used_memory_peak" => { :type => :gauge, :value => data['data']['memory']['used_memory_peak'].to_f, :source => name } #"=>"1012256",
    @queue.add "redis_memory_used_memory" => { :type => :gauge, :value => data['data']['memory']['used_memory'].to_f, :source => name } #"=>"921560",
    @queue.add "redis_memory_used_memory_rss" => { :type => :gauge, :value => data['data']['memory']['used_memory_rss'].to_f, :source => name } #"=>"2453504"}
    @queue.add "redis_cpu_used_cpu_sys_children" => { :type => :counter, :value => data['data']['cpu']['used_cpu_sys_children'].to_f, :source => name } #"=>"3.14",
    @queue.add "redis_cpu_used_cpu_user_children" => { :type => :counter, :value => data['data']['cpu']['used_cpu_user_children'].to_f, :source => name } #"=>"1.61",
    @queue.add "redis_cpu_used_cpu_sys" => { :type => :counter, :value => data['data']['cpu']['used_cpu_sys'].to_f.to_f, :source => name } #"=>"11058.11",
    @queue.add "redis_cpu_used_cpu_user" => { :type => :counter, :value => data['data']['cpu']['used_cpu_user'].to_f, :source => name } #"=>"4907.12"}
    @queue.add "redis_clients_client_biggest_input_buf" => { :type => :gauge, :value => data['data']['clients']['client_biggest_input_buf'].to_f, :source => name } #"=>"0",
    @queue.add "redis_clients_client_longest_output_list" => { :type => :gauge, :value => data['data']['clients']['client_longest_output_list'].to_f, :source => name } #"=>"0",
    @queue.add "redis_clients_blocked_clients" => { :type => :gauge, :value => data['data']['clients']['blocked_clients'].to_f, :source => name } #"=>"4",
    @queue.add "redis_clients_connected_clients" => { :type => :gauge, :value => data['data']['clients']['connected_clients'].to_f, :source => name } #"=>"8"}
    @queue.add "redis_replication_connected_slaves" => { :type => :gauge, :value => data['data']['replication']['connected_slaves'].to_f, :source => name } #"=>"0",
  }
end

def librato_vmstat
  puts "in #{__method__}"
  process_json("vmstat") { |data,name,json|
    @queue.add  "vmstat_CPU_context_switches" => { :type => :counter, :value => data['data']['CPU_context_switches'], :source => name }
    @queue.add  "vmstat_IO-wait_cpu_ticks" => { :type => :counter, :value => data['data']['IO-wait_cpu_ticks'], :source => name }
    @queue.add  "vmstat_IRQ_cpu_ticks" => { :type => :counter, :value => data['data']['IRQ_cpu_ticks'], :source => name }
    @queue.add  "vmstat_K_active_memory" => { :type => :gauge, :value => data['data']['K_active_memory'], :source => name }
    @queue.add  "vmstat_K_buffer_memory" => { :type => :gauge, :value => data['data']['K_buffer_memory'], :source => name }
    @queue.add  "vmstat_K_free_memory" => { :type => :gauge, :value => data['data']['K_free_memory'], :source => name }
    @queue.add  "vmstat_K_free_swap" => { :type => :gauge, :value => data['data']['K_free_swap'], :source => name }
    @queue.add  "vmstat_K_inactive_memory" => { :type => :gauge, :value => data['data']['K_inactive_memory'], :source => name }
    @queue.add  "vmstat_K_swap_cache" => { :type => :gauge, :value => data['data']['K_swap_cache'], :source => name }
    @queue.add  "vmstat_K_total_memory" => { :type => :gauge, :value => data['data']['K_total_memory'], :source => name }
    @queue.add  "vmstat_K_total_swap" => { :type => :gauge, :value => data['data']['K_total_swap'], :source => name }
    @queue.add  "vmstat_K_used_memory" => { :type => :gauge, :value => data['data']['K_used_memory'], :source => name }
    @queue.add  "vmstat_K_used_swap" => { :type => :gauge, :value => data['data']['K_used_swap'], :source => name }
    @queue.add  "vmstat_boot_time" => { :type => :gauge, :value => data['data']['boot_time'], :source => name }
    @queue.add  "vmstat_forks" => { :type => :counter, :value => data['data']['forks'], :source => name }
    @queue.add  "vmstat_idle_cpu_ticks" => { :type => :counter, :value => data['data']['idle_cpu_ticks'], :source => name }
    @queue.add  "vmstat_interrupts" => { :type => :counter, :value => data['data']['interrupts'], :source => name }
    @queue.add  "vmstat_nice_user_cpu_ticks" => { :type => :counter, :value => data['data']['nice_user_cpu_ticks'], :source => name }
    @queue.add  "vmstat_non-nice_user_cpu_ticks" => { :type => :counter, :value => data['data']['non-nice_user_cpu_ticks'], :source => name }
    @queue.add  "vmstat_pages_paged_in" => { :type => :counter, :value => data['data']['pages_paged_in'], :source => name }
    @queue.add  "vmstat_pages_paged_out" => { :type => :counter, :value => data['data']['pages_paged_out'], :source => name }
    @queue.add  "vmstat_pages_swapped_in" => { :type => :counter, :value => data['data']['pages_swapped_in'], :source => name }
    @queue.add  "vmstat_pages_swapped_out" => { :type => :counter, :value => data['data']['pages_swapped_out'], :source => name }
    @queue.add  "vmstat_softirq_cpu_ticks" => { :type => :counter, :value => data['data']['softirq_cpu_ticks'], :source => name }
    @queue.add  "vmstat_stolen_cpu_ticks" => { :type => :counter, :value => data['data']['stolen_cpu_ticks'], :source => name }
    @queue.add  "vmstat_system_cpu_ticks" => { :type => :counter, :value => data['data']['system_cpu_ticks'], :source => name }
  }
end

def librato_runit
  puts "in #{__method__}"
  process_json("runit") { |data,name,json|
    data['data'].each_pair do |k,v|
      unless /\*/.match(k) # XXX Fix this nonsense
        @queue.add "runit_#{k.split('/').last.gsub(':','')}" => { :type => :counter, :value => v['uptime'].to_i, :source => name }
      end
    end
  }
end

def librato_ping
  puts "in #{__method__}"
  process_json("ping") { |data,name,json|
    @queue.add  "ping_time_#{data['ip']}" => { :type => :gauge, :value => data['ping_time'], :source => name }
  }
end

def librato_memcache
  puts "in #{__method__}"
  process_json("memcache") { |data,name,json|
    @queue.add :memcache_uptime => { :type => :gauge, :value => data['data']['uptime'].to_i, :source => name} #value:21634968
    @queue.add :memcache_time => { :type => :counter, :value => data['data']['time'].to_i, :source => name} #time value:1372707119
    @queue.add :memcache_version => { :type => :gauge, :value => data['data']['version'].to_i, :source => name} #version value:1.4.5
    @queue.add :memcache_pointer_size => { :type => :gauge, :value => data['data']['pointer_size'].to_i, :source => name} #pointer_size value:64
    @queue.add :memcache_rusage_user => { :type => :gauge, :value => data['data']['rusage_user'].to_i, :source => name} #rusage_user value:16524.495894
    @queue.add :memcache_rusage_system => { :type => :gauge, :value => data['data']['rusage_system'].to_i, :source => name} #rusage_system value:66817.764155
    @queue.add :memcache_curr_connections => { :type => :gauge, :value => data['data']['curr_connections'].to_i, :source => name} #curr_connections value:2056
    @queue.add :memcache_total_connections => { :type => :gauge, :value => data['data']['total_connections'].to_i, :source => name} #total_connections value:7086154
    @queue.add :memcache_connection_structures => { :type => :gauge, :value => data['data']['connection_structures'].to_i, :source => name} #connection_structures value:4766
    @queue.add :memcache_cmd_get => { :type => :counter, :value => data['data']['cmd_get'].to_i, :source => name} #cmd_get value:25031115968
    @queue.add :memcache_cmd_set => { :type => :counter, :value => data['data']['cmd_set'].to_i, :source => name} #cmd_set value:1190405668
    @queue.add :memcache_cmd_flush => { :type => :counter, :value => data['data']['cmd_flush'].to_i, :source => name} #cmd_flush value:0
    @queue.add :memcache_get_hits => { :type => :counter, :value => data['data']['get_hits'].to_i, :source => name} #get_hits value:21987334777
    @queue.add :memcache_get_misses => { :type => :counter, :value => data['data']['get_misses'].to_i, :source => name} #get_misses value:3043781191
    @queue.add :memcache_delete_misses => { :type => :counter, :value => data['data']['delete_misses'].to_i, :source => name} #delete_misses value:66287299
    @queue.add :memcache_delete_hits => { :type => :counter, :value => data['data']['delete_hits'].to_i, :source => name} #delete_hits value:8856992
    @queue.add :memcache_incr_misses => { :type => :counter, :value => data['data']['incr_misses'].to_i, :source => name} #incr_misses value:0
    @queue.add :memcache_incr_hits => { :type => :counter, :value => data['data']['incr_hits'].to_i, :source => name} #incr_hits value:0
    @queue.add :memcache_decr_misses => { :type => :counter, :value => data['data']['decr_misses'].to_i, :source => name} #decr_misses value:0
    @queue.add :memcache_decr_hits => { :type => :counter, :value => data['data']['decr_hits'].to_i, :source => name} #decr_hits value:0
    @queue.add :memcache_cas_misses => { :type => :counter, :value => data['data']['cas_misses'].to_i, :source => name} #cas_misses value:0
    @queue.add :memcache_cas_hits => { :type => :counter, :value => data['data']['cas_hits'].to_i, :source => name} #cas_hits value:0
    @queue.add :memcache_cas_badval => { :type => :counter, :value => data['data']['cas_badval'].to_i, :source => name} #cas_badval value:0
    @queue.add :memcache_auth_cmds => { :type => :counter, :value => data['data']['auth_cmds'].to_i, :source => name} #auth_cmds value:0
    @queue.add :memcache_auth_errors => { :type => :counter, :value => data['data']['auth_errors'].to_i, :source => name} #auth_errors value:0
    @queue.add :memcache_bytes_read => { :type => :counter, :value => data['data']['bytes_read'].to_i, :source => name} #bytes_read value:17762979090001
    @queue.add :memcache_bytes_written => { :type => :counter, :value => data['data']['bytes_written'].to_i, :source => name} #bytes_written value:230035555826034
    @queue.add :memcache_limit_maxbytes => { :type => :gauge, :value => data['data']['limit_maxbytes'].to_i, :source => name} #limit_maxbytes value:6710886400
    @queue.add :memcache_accepting_conns => { :type => :gauge, :value => data['data']['accepting_conns'].to_i, :source => name} #accepting_conns value:1
    @queue.add :memcache_listen_disabled_num => { :type => :gauge, :value => data['data']['listen_disabled_num'].to_i, :source => name} #listen_disabled_num value:0
    @queue.add :memcache_threads => { :type => :gauge, :value => data['data']['threads'].to_i, :source => name} #threads value:8
    @queue.add :memcache_conn_yields => { :type => :counter, :value => data['data']['conn_yields'].to_i, :source => name} #conn_yields value:16989
    @queue.add :memcache_bytes => { :type => :counter, :value => data['data']['bytes'].to_i, :source => name} #bytes value:5704751359
    @queue.add :memcache_curr_items => { :type => :gauge, :value => data['data']['curr_items'].to_i, :source => name} #curr_items value:5933543
    @queue.add :memcache_total_items => { :type => :gauge, :value => data['data']['total_items'].to_i, :source => name} #total_items value:1190405668
    @queue.add :memcache_evictions => { :type => :counter, :value => data['data']['evictions'].to_i, :source => name} #evictions value:9687927
    @queue.add :memcache_reclaimed => { :type => :counter, :value => data['data']['reclaimed'].to_i, :source => name} #reclaimed value:59695476
  }
end


def librato_rss
  puts "in #{__method__}"
  process_json("process") do |data,name,json|
    if /stag|prod/.match(name)
      data['data'].select{|k,v| /node/.match(v[7]) }.each do |x,y|
        #puts "pid:#{x} rss: #{y[5]} name:#{y[7..-1].join(" ")}"
        @queue.add :node_rss => { :type => :gauge, :value => y[5], :source => "#{name}-#{x}"}
      end
      data['data'].select{|k,v| /unicorn worker/.match(v[7..-1].join(" ")) }.each do |x,y|
        #puts "pid:#{x} rss: #{y[5]} name:#{y[7..-1].join(" ")}"
        @queue.add :unicorn_rss => { :type => :gauge, :value => y[5], :source => "#{name}-#{x}"}
      end

      data['data'].select{|k,v| /Rack/.match(v[7]) }.each do |x,y|
        #puts "pid:#{x} rss: #{y[5]} name:#{y[7..-1].join(" ")}"
        @queue.add :passenger_rss => { :type => :gauge, :value => y[5], :source => "#{name}-#{x}"}
      end

    end
  end
end


metrics = [ 
    :load, 
    :memfree,
    :netstat,
    :redis,
    :vmstat,
    :ping,
    :runit,
    :memcache,
    :rss
  ]

metrics.each do |m|
  @queue = Librato::Metrics::Queue.new
  send("librato_#{m}")
  begin
  @queue.submit
    rescue Exception => e
      File.open("/data/ec2read/librato_submit_librato.err", "a+") {|f|
        f.puts "Librato did not like our data #{e.inspect}"
      }
    end
end

#librato_load
#librato_memfree
#librato_netstat
#librato_redis
#librato_vmstat
#librato_ping
#librato_runit
#librato_memcache
#librato_rss

