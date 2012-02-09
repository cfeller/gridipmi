#!/usr/bin/env ruby1.9

#
# socks and zcmd tester
#
# author  = Chad Feller
# version = 0.1
# date    = 20 Jun 2011
#

# tested with: freeipmi-0.8.8-1.fc14.x86_64
# freeipmi seems to be evolving still, e.g., option flags
# you have been warned
#

$ipmitool = 'ipmitool'
$ipmitool_preargs = ' -U root -P $(cat ~/.secure/pw) -H '
$ipmitool_ch_pwr_st = ' chassis power status'
$ipmitool_fru0 = ' fru print 0'
$ipmitool_fru3 = ' fru print 3'

$ipmi_sensors = '/usr/sbin/ipmi-sensors'
$ipmi_preargs = ' -u root -p $(cat ~/.secure/pw) -h '
$ipmi_no_hdr = ' --no-header-output '
$ipmi_comma_out = ' --comma-separated-output '
$ipmi_pa_snsr_tmp = ' --sensor-types=temperature '
$ipmi_pa_rcrd_id = ' --record-id '
$ipmi_pa_v = ' -v'

class Ilom

  def initialize(hostname = "localhost")
    @hostname = hostname
    @ipmi_authcap = check_authcap_needed
    @ipmi_endianseq = check_endianseq_needed
    @mbt_amb,@mbt_amb_id = find_temperature_device
    @cur_temp = read_cur_temp
    @temp_status = read_cur_temp_status
    @thresh_unc,@thresh_ucr,@thresh_unr = read_temp_thresholds
    @watermark_high = @watermark_low = get_temp
  end

  def get_hostname
    @hostname
  end

  def print_hostname
    puts #{@hostname}
  end

  def get_chassis_power_status
    %x[#{$ipmitool} #{$ipmitool_preargs} #{@hostname} #{$ipmitool_ch_pwr_st}]
  end

  # authcap workaround needed for elom
  def check_authcap_needed
    b = %x[#{$ipmitool} #{$ipmitool_preargs} #{@hostname} #{$ipmitool_fru0}]
    if b.include?("Device not present")
      ' -W authcap'
    else
      ''
    end
  end

  # from the freeipmi man page:
  # "endianseq" - This workaround option will flip the endian of  the  ses-
  # sion  sequence  numbers  to allow the session to continue properly.  It
  # works around IPMI 1.5 session  sequence  numbers  that  are  the  wrong
  # endian.  Those  hitting  this  issue  may see "session timeout" errors.
  # Issue observed on some Sun ILOM 1.0/2.0 (depends on  service  processor
  # endian).
  # //end manpage output
  #
  # early ILOMS seem to spit out something like:
  # Board Mfg Date        : Sun Dec 31 15:00:00 1995
  # Board Product         : ASSY,SERV PROCESSOR,A64/A65
  # Board Serial          : 1762TH1-0637002467
  # Board Part Number     : 501-6979-05
  # Board Extra           : 50
  # Board Extra           : A64/A65_GRASP
  # Product Manufacturer  : SUN MICROSYSTEMS
  # Product Name          : ILOM
  #
  # for an fru 0 (ipmitool output).  Based off of this output, I'm crudely
  # trying to detect the devices in question.
  # A future TODO would be to determine the need for this flag more accurately
  def check_endianseq_needed
    b = %x[#{$ipmitool} #{$ipmitool_preargs} #{@hostname} #{$ipmitool_fru0}]
    if b.include?("GRASP") || b.include?("ASSY,SERV PROCESSOR,X4600,REV")
      ' -W endianseq'
    else
      ''
    end
  end
  
  def read_cur_temp(id = get_temp_id)
    # 17,/MB/T_AMB,Temperature,25.00,C,'OK'\n"
    @cur_temp = %x[#{$ipmi_sensors} #{@ipmi_authcap} #{@ipmi_endianseq} #{$ipmi_preargs} #{@hostname} #{$ipmi_pa_rcrd_id} #{id} #{$ipmi_no_hdr} #{$ipmi_comma_out}].split(",")[3]
  end

  def get_temp
    @cur_temp
  end

  def read_temp_thresholds
    d = %x[#{$ipmi_sensors} #{@ipmi_authcap} #{@ipmi_endianseq} #{$ipmi_preargs} #{@hostname} #{$ipmi_pa_rcrd_id} #{@mbt_amb_id} #{$ipmi_pa_v} #{$ipmi_no_hdr}].split("\n")
    a = b = c = " "
    d.each do |x|
      if x.include?("Upper Non-Critical")
        a = x.split()[3]
#        puts "\tHere: " + a.to_s
      end
      if x.include?("Upper Critical")
        b = x.split()[3]
      end
      if x.include?("Upper Non-Recoverable")
        #this should be the last one we come across, return
        c = x.split()[3]
        return a,b,c
      end
    end
  end

  def get_temp_thresholds
    return @thresh_unc,@thresh_ucr,@thresh_unr
    # @thresh_ucr
  end

  def read_cur_temp_status 
    # 17,/MB/T_AMB,Temperature,25.00,C,'OK'
    t = %x[#{$ipmi_sensors} #{@ipmi_authcap} #{@ipmi_endianseq} #{$ipmi_preargs} #{@hostname} #{$ipmi_pa_rcrd_id} #{@mbt_amb_id} #{$ipmi_no_hdr} #{$ipmi_comma_out}].split(",")[5]
    # trim the single quotes from both ends
    t.to_s.chomp.reverse.chop.reverse.chop
  end

  def get_temp_status
    @temp_status
  end

  def get_temp_id
    @mbt_amb_id
  end

  def get_temp_device
    @mbt_amb
  end

  def find_temperature_device
    b = %x[#{$ipmi_sensors} #{@ipmi_authcap} #{@ipmi_endianseq} #{$ipmi_preargs} #{@hostname} #{$ipmi_pa_snsr_tmp} #{$ipmi_comma_out}]
    a = b.split("\n")
    a.each do |x|
      # Sun ILOM
      if x.include?("t_amb") || x.include?("T_AMB")
        return x.split(",")[1],x.split(",")[0] #return Device Name, ID
      elsif x.include?("Ambient Temp") #ELOM or DRAC
        # make sure there is actually a sensor there
        c = read_cur_temp(x.split(",")[0])
        if c != "N/A"
          return x.split(",")[1],x.split(",")[0] #return Device Name, ID
        end
      end  
    end
  end
  
end
