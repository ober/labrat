#!/usr/bin/env ruby
require 'librato/metrics'
require 'yaml'
require 'json'

@config = YAML::load(File.read("#{ENV['HOME']}/.librato.yml"))
Librato::Metrics.authenticate @config['email'], @config['api_token']

# Handle VMSTAT output
Dir.glob("#{ENV['HOME']}/out/*vmstat.json") do |json|
  data = JSON.parse(File.read(json))
  name = json.split("-vmstat.json").to_s.split("/").last.gsub(/\"/,'').gsub(/\]/,'')
  if data['status']['value'] == "OK"
    puts "putting name:#{name}"
    queue = Librato::Metrics::Queue.new
    queue.add  :pinky_metric => { :type => :counter, :value => 1002, :source => 'testbox'}
    queue.add  "vmstat_CPU_context_switches" => { :type => :gauge, :value => data['data']['CPU_context_switches'], :source => name }
    queue.add  "vmstat_IO-wait_cpu_ticks" => { :type => :gauge, :value => data['data']['IO-wait_cpu_ticks'], :source => name }
    queue.add  "vmstat_IRQ_cpu_ticks" => { :type => :gauge, :value => data['data']['IRQ_cpu_ticks'], :source => name }
    queue.add  "vmstat_K_active_memory" => { :type => :gauge, :value => data['data']['K_active_memory'], :source => name }
    queue.add  "vmstat_K_buffer_memory" => { :type => :gauge, :value => data['data']['K_buffer_memory'], :source => name }
    queue.add  "vmstat_K_free_memory" => { :type => :gauge, :value => data['data']['K_free_memory'], :source => name }
    queue.add  "vmstat_K_free_swap" => { :type => :gauge, :value => data['data']['K_free_swap'], :source => name }
    queue.add  "vmstat_K_inactive_memory" => { :type => :gauge, :value => data['data']['K_inactive_memory'], :source => name }
    queue.add  "vmstat_K_swap_cache" => { :type => :gauge, :value => data['data']['K_swap_cache'], :source => name }
    queue.add  "vmstat_K_total_memory" => { :type => :gauge, :value => data['data']['K_total_memory'], :source => name }
    queue.add  "vmstat_K_total_swap" => { :type => :gauge, :value => data['data']['K_total_swap'], :source => name }
    queue.add  "vmstat_K_used_memory" => { :type => :gauge, :value => data['data']['K_used_memory'], :source => name }
    queue.add  "vmstat_K_used_swap" => { :type => :gauge, :value => data['data']['K_used_swap'], :source => name }
    queue.add  "vmstat_boot_time" => { :type => :gauge, :value => data['data']['boot_time'], :source => name }
    queue.add  "vmstat_forks" => { :type => :counter, :value => data['data']['forks'], :source => name }
    queue.add  "vmstat_idle_cpu_ticks" => { :type => :counter, :value => data['data']['idle_cpu_ticks'], :source => name }
    queue.add  "vmstat_interrupts" => { :type => :counter, :value => data['data']['interrupts'], :source => name }
    queue.add  "vmstat_nice_user_cpu_ticks" => { :type => :counter, :value => data['data']['nice_user_cpu_ticks'], :source => name }
    queue.add  "vmstat_non-nice_user_cpu_ticks" => { :type => :counter, :value => data['data']['non-nice_user_cpu_ticks'], :source => name }
    queue.add  "vmstat_pages_paged_in" => { :type => :counter, :value => data['data']['pages_paged_in'], :source => name }
    queue.add  "vmstat_pages_paged_out" => { :type => :counter, :value => data['data']['pages_paged_out'], :source => name }
    queue.add  "vmstat_pages_swapped_in" => { :type => :counter, :value => data['data']['pages_swapped_in'], :source => name }
    queue.add  "vmstat_pages_swapped_out" => { :type => :counter, :value => data['data']['pages_swapped_out'], :source => name }
    queue.add  "vmstat_softirq_cpu_ticks" => { :type => :counter, :value => data['data']['softirq_cpu_ticks'], :source => name }
    queue.add  "vmstat_stolen_cpu_ticks" => { :type => :counter, :value => data['data']['stolen_cpu_ticks'], :source => name }
    queue.add  "vmstat_system_cpu_ticks" => { :type => :counter, :value => data['data']['system_cpu_ticks'], :source => name }
    queue.submit
  end
end
