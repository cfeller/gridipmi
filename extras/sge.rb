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
# $qstata2 = 'qstat -u '\''*'\'''

$qstat_pa_tr_xml = ' -t -r -xml '

class IlomSGE

  def initialize
    @jobs = find_all_running_jobs
    @drmaa_session = DRMAA::Session.new
  end
  
  def find_all_running_jobs
    @jobs = %x[#{$qstata} #{$qstat_pa_tr_xml}]
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
