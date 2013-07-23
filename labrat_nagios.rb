#!/usr/bin/env ruby
require 'json'
require 'pp'

@monitor,@host,@warn,@crit = ARGV[0..3]

@dir = "/data/ec2read/production"

def process_json(file,&block)
  begin
    data = JSON.parse(File.read(file))
    name = data['system']['name'] if data and data['system'] and data['system']['name']
    if data and data['status'] and data['status']['value'] == "OK"
      yield(data)
    end
  rescue Exception => e
    puts "Invalid json. Could not read #{file}: error #{e.message}"
  end
end

def monitor_disk()
  ok_out = "OK:" 
  warn_out = "Warn:"
  warn_count = 0
  crit_out = "Crit:"
  crit_count = 0
  process_json("#{@dir}/#{@host}-#{@monitor}.json") do |data,name,json|
    data['data'].each_pair do |k,v|
      if k == "/" or k == "/data"
        if v.last.to_i >= (100 - @crit.to_i)
          crit_out << "#{k}: #{v.last} free," 
          crit_count += 1
        elsif v.last.to_i >= (100 - @warn.to_i)
          warn_out << "#{k}: #{v.last} free," 
          warn_count += 1
        elsif 
          ok_out << ",#{k} = #{v.last} free"
        end
      end
    end
  end
  if crit_count > 0
    crit_out
  elsif warn_count > 0
    warn_out
  else
    ok_out
  end
end

def monitor_memory()
  ok_out = "OK:" 
  warn_out = "Warn:"
  warn_count = 0
  crit_out = "Crit:"
  crit_count = 0
  process_json("#{@dir}/#{@host}-#{@monitor}.json") do |data,name,json|
    perfree = (data['data']['bc_free'].to_f/data['data']['total'].to_f * 100).to_i
    if perfree <= @crit.to_i
      crit_out << "#{perfree}% free"
      crit_count += 1
    elsif perfree <= @warn.to_i
      warn_out << "#{perfree}% free"
      warn_count += 1
    elsif 
      ok_out << "#{perfree}% free"
    end
  end

  if crit_count > 0
    crit_out
  elsif warn_count > 0
    warn_out
  else
    ok_out
  end
end

def monitor_load()
  ok_out = "OK:" 
  warn_out = "Warn:"
  warn_count = 0
  crit_out = "Crit:"
  crit_count = 0
  process_json("#{@dir}/#{@host}-#{@monitor}.json") do |data,name,json|
    one,five,fifteen = data['data']['one'].to_f, data['data']['five'].to_f, data['data']['fifteen'].to_f

    if fifteen >= @crit.to_f
      crit_out << "15min load is #{fifteen}"
      crit_count += 1
    elsif fifteen >= @warn.to_f
      warn_out << "15min load is #{fifteen}"
      warn_count += 1
    elsif 
      ok_out << "15min load is #{fifteen}"
    end
  end

  if crit_count > 0
    puts crit_out
    exit(2)
  elsif warn_count > 0
    puts warn_out
    exit(1)
  else
    puts ok_out
    exit(0)`
  end
end


case @monitor
when "disk"
  puts monitor_disk()
when "memfree"
  puts monitor_memory()
when "load"
  puts monitor_load()
else
  puts "Fail: No monitor #{@monitor}"
end


