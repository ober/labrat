#!/usr/bin/env ruby

require 'json'
require 'pp'

@monitor,@host,@warn,@crit = ARGV[0..3]

@ok_out,@warn_out,@crit_out,@warn_count,@crit_count = "OK:","Warn:","Crit:",0,0

@dir = "/data/ec2read/production"

def process_json(file,&block)
  begin
    data = JSON.parse(File.read(file))
  rescue Exception => e
    puts "Invalid json. Could not read #{file}: error #{e.message}"
  end
  name = data['system']['name'] if data and data['system'] and data['system']['name']
  if data and data['status'] and data['status']['value'] == "OK"
    yield(data)
  end
end

def monitor_generic(&block)
  process_json("#{@dir}/#{@host}-#{@monitor}.json") do |data,name,json|
    yield(data,name,json)
    if @crit_count > 0
      puts @crit_out
      exit(2)
    elsif @warn_count > 0
      puts @warn_out
      exit(1)
    else
      puts @ok_out
      exit(0)
    end
  end
end

def crit(msg)
  @crit_out << msg
  @crit_count += 1
end

def warn(msg)
  @warn_out << msg
  @warn_count += 1
end

def ok(msg)
  @ok_out << msg
end

def monitor_disk()
  monitor_generic do |data,name,json|
    data['data'].each_pair do |k,v|
      if k == "/" or k == "/data"
        used = v.last.to_i
        free = 100 - used
        if used >= @crit.to_i
          crit " #{k}: #{free}% free," 
        elsif used >= @warn.to_i
          warn " #{k}: #{free}% free," 
        elsif 
          ok " #{k} = #{free}% free"
        end
      end
    end
  end
end

def monitor_memfree()
  monitor_generic do |data,name,json|
    perfree = (data['data']['bc_free'].to_f/data['data']['total'].to_f * 100).to_i
    if perfree <= @crit.to_i
      crit "#{perfree}% free"
    elsif perfree <= @warn.to_i
      warn "#{perfree}% free"
    elsif 
      ok "#{perfree}% free"
    end
  end
end

def monitor_load()
  monitor_generic do |data,name,json|
    one,five,fifteen = data['data']['one'].to_f, data['data']['five'].to_f, data['data']['fifteen'].to_f
    if fifteen >= @crit.to_f
      crit "15min load is #{fifteen}"
    elsif fifteen >= @warn.to_f
      warn "15min load is #{fifteen}"
    elsif 
      ok "15min load is #{fifteen}"
    end
  end
end

def monitor_dpkg()
  monitor_generic do |data,name,json|
    security, pending = data['data']['updates']['security'],data['data']['updates']['be']
    msg = "Pending security fixes are: #{security.first.to_i}"
    if security.first.to_f >= @crit.to_f
      crit msg
    elsif security.first.to_f >= @warn.to_f
      warn msg
    elsif 
      ok msg
    end
  end
end

def monitor_stat()
  monitor_generic do |data,name,json|
    delta = data['system']['time'] - data['data']['modification']
    msg = "System last cooked: #{(delta.to_f/84600).to_i} days ago"
    if delta.to_i >= @crit.to_i
      crit msg
    elsif delta >= @warn.to_i
      warn msg
    elsif 
      ok msg
    end
  end
end


puts send("monitor_#{@monitor}")
