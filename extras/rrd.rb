#/usr/bin/env ruby

#
# RRD ilom access
#
# author  = Chad Feller
# version = 0.1
# date    = 11 Nov 2011
#

#rrdtool create firefox_mem.rrd --start $(date +%s) --step 10 DS:mem:GAUGE:30:U:U RRA:AVERAGE:0.5:3:120 RRA:AVERAGE:0.5:360:24

#rrd = {:name => "localhost", :step => 60, :ds_label => "mem", :ds_type => "GAUGE", :ds_heartbeat => 120, :min => "U", :max => "U"}
#rra1 = {:cf => "AVERAGE", :xff => 0.5, :step => 2, :rows => 720} # 24 hours
#rra2 = {:cf => "AVERAGE", :xff => 0.5, :step => 5, :rows => 8928} # 31 days

#rrd[:rra1] = rra1
#rrd[:rrd2] = rra2


require "RRD"

class IlomRRD

  def initialize(h)
    @name = h[:db_path] + "/" + h[:name] + ".rrd"
    @r_db_path = (h[:db_path] + "/").reverse
#    @basename = h[:name]
    @graphname = h[:img_path] + "/" + h[:name] + ".png"
    @graphname_sm = h[:img_path_sm] + "/" + h[:name] + ".png"
    @start_time = Time.now.to_i
#    @end_time = 10000              # TODO: change me
    @step = h[:step]
    @ds_label = h[:ds_label]
    @ds_type = h[:ds_type]
    @ds_heartbeat = h[:ds_heartbeat]
    @ds_min = h[:min]
    @ds_max = h[:max]
    #DS:variable_name:DST:heartbeat:min:max
    #DS:mem:GAUGE:60:U:U
    @ds = "DS:#{@ds_label}:#{@ds_type}:#{@ds_heartbeat}:#{@ds_min}:#{@ds_max}"
    #RRA:CF:xff:step:rows
    #RRA:AVERAGE:0.5:2:720
    #RRA:AVERAGE:0.5:5:8928
    @rra1 = "RRA:#{h[:rra1][:cf]}:#{h[:rra1][:xff]}:#{h[:rra1][:step]}:#{h[:rra1][:rows]}"
    @rra2 = "RRA:#{h[:rra2][:cf]}:#{h[:rra2][:xff]}:#{h[:rra2][:step]}:#{h[:rra2][:rows]}"
    @rra_cf = "#{h[:rra1][:cf]}" #assumed "default" CF for graph method
  end

  def create
    puts "creating #{@name}"
    RRD.create(
               @name,
               "--start", "#{@start_time - 1}", #not sure about the "-1", but several examples have it
               "--step", "#{@step}",
               "#{@ds}",
               "#{@rra1}",
               "#{@rra2}"
               )
  end

  def update v
    puts "updating #{@name} with N:#{v}"
    RRD.update(             
               @name,
               "N:#{v}"
               )
  end
  
  #rrdtool graph firefox_mem.png --start 1317535605 --end $(date +%s) DEF:ffmem=firefox_mem.rrd:mem:AVERAGE LINE2:ffmem#FF0000

  # graphing methods
  # "t" holds temperature thresholds to be placed in graphs
  # regular graph function
  def graph t
    puts "graphing #{@graphname}"
    $end_time = Time.now.to_i - @step + 1
    $start_time = $end_time - 3600 #one hour
    $unc, $ucr, $unr = t
    RRD.graph(
              "#{@graphname}",
              "--title", "#{@name.reverse.chomp(@r_db_path).reverse.chomp(".rrd")}",
#              "--vertical-label","Ambient Temp",
              "--start", "#{$start_time}",
              "--end", "#{$end_time}",
              "--interlaced",
              "--imgformat", "PNG",
              "DEF:amb_#{@ds_label}=#{@name}:#{@ds_label}:#{@rra_cf}",
              "LINE1:amb_#{@ds_label}#555555:Ambient Temperature",
              "HRULE:#{$unc}#FF4500:Threshold - Non-Critical",
              "HRULE:#{$ucr}#FF0000:Threshold - Critical"
              )
  end
  
  #"small" graph function
  def graph_sm t
    puts "graphing #{@graphname_sm}"
    $end_time = Time.now.to_i - @step + 1
    $start_time = $end_time - 3600 #one hour
    $unc, $ucr, $unr = t
    RRD.graph(
              "#{@graphname_sm}",
              "--title", "#{@name.reverse.chomp(@r_db_path).reverse.chomp(".rrd")}",
#              "--vertical-label","Ambient Temp",
              "--start", "#{$start_time}",
              "--end", "#{$end_time}",
              "--interlaced",
              "--imgformat", "PNG",
              "--width=160",
              "--height=80",
              "DEF:amb_#{@ds_label}=#{@name}:#{@ds_label}:#{@rra_cf}",
              "LINE1:amb_#{@ds_label}#555555:Ambient Temp",
              "HRULE:#{$unc}#FF4500:Non-Critical Thresh",
              "HRULE:#{$ucr}#FF0000:Critical Thresh"
              )
  end
  
end
