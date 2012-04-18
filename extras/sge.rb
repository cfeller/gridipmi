#!/usr/bin/env ruby1.9

#
# socks and zcmd tester
#
# author  = Chad Feller
# version = 0.1
# date    = 24 February 2012
#

# TODO: class description here
# 
# 
#

require 'rubygems'
require 'drmaa'
require 'nokogiri'

# qstata -t -r -xml > qstata_t_r.xml

$qstata = "qstat -u '*'"

$qconf_sql = "qconf -sql"

$qmod_sq = "qmod -sq"
$qmod_d = "qmod -d"

$qmod_usq = "qmod -usq"
$qmod_e = "qmod -e"

$qmod_sj = "qmod -sj"
$qmod_usj = "qmod -usj"

$qstat_pa_tr_xml = ' -t -r -xml '
$qstat_pa_tr_sr_xml = ' -t -r -s r -xml '
$qstat_pa_tr_ss_xml = ' -t -r -s s -xml '

$qstat_F_numproc_ss_xml = 'qstat -F num_proc -s s -xml '

class IlomSGE

  def initialize
    @jobs = find_all_running_jobs
    @drmaa_session = DRMAA::Session.new
  end
  
  def find_all_running_jobs
    @jobs = %x[#{$qstata} #{$qstat_pa_tr_sr_xml}]
  end

  def find_all_suspended_jobs
    @sjobs = %x[#{$qstata} #{$qstat_pa_tr_ss_xml}]
  end

  def find_open_slots
    @oslots = %x[#{$qstat_F_numproc_ss_xml}]
  end
  
  def find_jobs_on_node(node)

    job_list = []
    doc = Nokogiri::XML(@jobs.to_s)
    
    doc.xpath("//queue_name").each do |x|
      if x.content.include?(node)
        job_list.push(x.at_xpath("../JB_job_number").content)
      end
    end
    job_list.uniq!
    job_list
  end

  def get_queue_list
    %x[#{$qconf_sql}]
  end

  def suspend_queues #suspends queues, currently running jobs also suspended
    get_queue_list.split.each do |x|
      %x[#{$qmod_sq} #{x}]
    end
  end

  def unsuspend_queues #unsuspends queues, currently running jobs also unsuspended
    get_queue_list.split.each do |x|
      %x[#{$qmod_usq} #{x}]
    end
  end

  def close_queues #disables (closes) queues, currently running jobs finish 
    get_queue_list.split.each do |x|
      %x[#{$qmod_d} #{x}]
    end
  end

  def open_queues #enables (opens) queues
    get_queue_list.split.each do |x|
      %x[#{$qmod_e} #{x}]
    end
  end

  def suspend_all_jobs

    find_all_running_jobs
    
    doc = Nokogiri::XML(@jobs.to_s)
    
    doc.xpath("//JB_job_number").each do |x|
      a = x.content
      %x[#{$qmod_sj} #{a}]
    end
  end

  def unsuspend_all_jobs

    find_all_suspended_jobs
    
    doc = Nokogiri::XML(@sjobs.to_s)
    
    doc.xpath("//JB_job_number").each do |x|
      a = x.content
      %x[#{$qmod_usj} #{a}]
    end
  end

  def find_free_nodes

    find_open_slots
    
    slot_list = []
    doc = Nokogiri::XML(@oslots.to_s)

    doc.xpath("//slots_used").each do |x|
      if x.content == "0"
        slot_list.push(x.at_xpath("../name").content.split("@")[1].chomp(".local"))
      end
    end
    slot_list.uniq!
    slot_list
    
  end
  
  

  # drmaa based calls below
  
  def suspend_job(id)
    @drmaa_session.suspend(id)
  end

  def resume_job(id)
    @drmaa_session.resume(id)
  end

  def terminate_job(id)
    @drmaa_session.terminate(id)
  end
  
  
end

#######################################################################
# testing
#

if __FILE__ == $0
  
  a = IlomSGE.new()
  jl = a.find_jobs_on_node(ARGV[0])
  #puts jl.class
  jl.each {|x| a.suspend_job x}
  sleep 20
  jl.each {|x| a.resume_job x}
  
end
