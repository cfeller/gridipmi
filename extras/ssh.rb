#!/usr/bin/env ruby1.9

#
# socks and zcmd tester
#
# author  = Chad Feller
# version = 0.1
# date    = 15 Apr 2011
#

require 'net/ssh'

class GridSSH
  
  def shutdown_node(n)
    puts "shutting down "+n+" now!!!"
    Net::SSH.start( n, "feller") do |ssh|
      ssh.open_channel do |channel|
        channel.request_pty do |c, success|
          if success
            puts "success!" #debug, remove later
            command = "sudo /sbin/shutdown -h now"
            c.exec(command) do |c, success|
              puts "inside!" #debug, remove later 
            end
          end
        end
      end #channel.request_pty
    end #ssh.start
  end #def

  
end
