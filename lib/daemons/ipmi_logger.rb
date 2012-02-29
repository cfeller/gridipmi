#!/usr/bin/env ruby

# You might want to change this
#ENV["RAILS_ENV"] ||= "production"
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/application"
Rails.application.require_environment!

require "ilom"
require "rrd"
require "yaml"

Dir.chdir("/mnt/brick/.gridipmi")

loc = YAML::load(File.open('config/layout.yml')) #load physical layout
# load host locations into model
loc.each_key do |x|
  loc[x].each_key do |y|
    if !( z = Location.find_by_hostname(loc[x][y]) )
      t = Location.create( { :rack => x , :rank => y , :hostname => loc[x][y] } )
      t.save
    end
  end
end

# load RRD DB config
yml = YAML::load(File.open('config/rrd_config.yml'))
rrd = yml[:rrd]


hostlist = {} # {hostname => bmcname}

# parse hostfile, which is a list of pairings of the format:
#   hostname bmcname
#
# and load values into hostlist
# hostlist will be used once, as a mapping of sorts, to help populate nodelist.
hostfile="hosts.txt"
fhandle = open(hostfile, "r")
begin
  while (x = fhandle.readline.split)
    hostlist[x[0]] = x[1]
  end
rescue EOFError
  fhandle.close
end

nodelist = {} # {hostname => { :bmc => Ilom object , :rrd => IlomRRD object, :node_id => Node ID } }

# populate nodelist{}, and check if node already exists in DB.  if not,
# load data in DB.  If it does, just get :node_id for quick access later.

# TODO (optimization): load ILOM object from DB (if it already exists) to
# alleviate having to probe for all values at each startup.
hostlist.each_key do |x|
  rrd[:name] = x
  nodelist[x] = { :bmc => Ilom.new(hostlist[x]), :rrd => IlomRRD.new(rrd) }
  # a quick mapping because the Node model (currently) doesn't
  # consider the Ilom to be a separate entity and the Ruby classes do.
  if !( n = Node.find_by_hostname(x) )
    t = Node.create( { :hostname => x } )
    nodelist[x][:node_id] = t.id
    t.hostname = x
    t.watermark_low = t.watermark_high = t.cur_temp = nodelist[x][:bmc].get_temp
    t.temp_status = nodelist[x][:bmc].get_temp_status
    t.thresh_unc, t.thresh_ucr, t.thresh_unr = nodelist[x][:bmc].get_temp_thresholds
    t.thresh_unr = t.thresh_unr[0,4] #trim (thresh_unr is a string, ATM)
    t.def_thresh_unc, t.def_thresh_ucr, t.def_thresh_unr = t.thresh_unc, t.thresh_ucr, t.thresh_unr # set defaults
    t.mbt_amb = nodelist[x][:bmc].get_temp_device
    t.mbt_amb_id = nodelist[x][:bmc].get_temp_id
    t.location = Location.find_by_hostname(x)
    t.save
  else
    nodelist[x][:node_id] = n.id
  end
end

#create rrd db dir
if ! File.directory?(rrd[:db_path])
  Rails.logger.auto_flushing = true
  Rails.logger.info "Trying to make db directories in #{Dir.pwd}."
  Dir.mkdir(rrd[:db_path])
end

#create graph output dir
if ! File.directory?(rrd[:img_path])
  Rails.logger.auto_flushing = true
  Rails.logger.info "Trying to make img directories in #{Dir.pwd}."
  Dir.mkdir(rrd[:img_path])
  Dir.mkdir(rrd[:img_path_sm])
end

#create rrds
nodelist.each_key do |x|
  #create dirs if they don't exist
  if ! File.directory?(rrd[:db_path])
    Rails.logger.auto_flushing = true
    Rails.logger.info "Trying to make directory in #{Dir.pwd}."
    Dir.mkdir(rrd[:db_path])
  end
  nodelist[x][:rrd].create
end
        
$running = true
Signal.trap("TERM") do 
  $running = false
end

$y=0
while($running) do

  $y += 1
  $delta = Time.now.to_i
  
  nodelist.each_key do |x|
    if 'N/A' != nodelist[x][:bmc].read_cur_temp #X4140s occasionally return 'N/A'.  If so, we pass.
    
      nodelist[x][:rrd].update(nodelist[x][:bmc].get_temp) #update RRD

      t = Node.find(nodelist[x][:node_id])
      t.cur_temp = nodelist[x][:bmc].get_temp #update SQL
      t.watermark_high = t.cur_temp if t.cur_temp > t.watermark_high
      t.watermark_low = t.cur_temp if t.cur_temp < t.watermark_low
      t.save
      #puts nodelist[x][:bmc].get_hostname
      if $y % 5 == 0
        # graph temps - rrd object already has temps, pull updated
        # thresholds in case they've been changed.
        # TODO: pull updated thresholds from DB???
        $thresholds = t.thresh_unc, t.thresh_ucr, t.thresh_unr # grab current thresholds from DB
        # nodelist[x][:rrd].graph(nodelist[x][:bmc].get_temp_thresholds) #large graphs
        # nodelist[x][:rrd].graph_sm(nodelist[x][:bmc].get_temp_thresholds) #small graphs
        puts "thresholds are: "
        puts $thresholds
        puts " "
        nodelist[x][:rrd].graph($thresholds) #large graphs
        nodelist[x][:rrd].graph_sm($thresholds) #small graphs
        $y = 0 #we don't want y to go Bignum
      end
    else
      puts "'N/A' returned, punting"
      Rails.logger.auto_flushing = true
      Rails.logger.info nodelist[x][:bmc].get_hostname+"returned 'N/A', punting"
    end
  end
  
  $delta -= Time.now.to_i
  begin
    sleep 60 + $delta
  rescue ArgumentError
    puts "Lost "+(-60 - $delta).to_s+" ticks!!!"
    Rails.logger.auto_flushing = true
    Rails.logger.info "Lost "+(-60 - $delta).to_s+" ticks!!!"
  end
  
end
