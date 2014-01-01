#!/usr/bin/env ruby
require 'librato/metrics'
require 'yaml'
require 'json'

@config = YAML::load(File.read("#{ENV['HOME']}/.librato.yml"))
Librato::Metrics.authenticate @config['email'], @config['api_token']

# Handle netstat -s output
queue = Librato::Metrics::Queue.new

Dir.glob("#{ENV['HOME']}/ec2read/out/*netstat.json") do |json|
  data = JSON.parse(File.read(json))
  name = data['system']['name'] if data and data['system'] and data['system']['name']
  name ||= json.split("-netstat.json").to_s.split("/").last.gsub(/\"/,'').gsub(/\]/,'')

  if data['status']['value'] == "OK"
    puts "putting name:#{name}"
    
    data['data'].each_pair do |k,v| 
      queue.add "netstat_#{k}" => { :type => :counter, :value => v, :source => name }
    end


  else
    puts "wtf: #{name}"
  end
end
queue.submit
