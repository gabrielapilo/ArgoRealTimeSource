#! /usr/bin/perl -I/usr/local/include
#
#	Generate an Argo BUFR message from Argo netCDF profile file.
#	Version 1 for the template adopted by ET/DRC in December 2005.
#	Version 2 for not using netCDF perl interface (using ncdump only)
#	Version 3.0 for v3.1 profile files
#	Version 3.1 for v3.1 profile and bio file
#
#
# ========================================================================
#
# *** Notice ***
# Identification of generating center and path of "ncdump" command should be specified.
#
# Identification of generating center
# default value is 34: JMA Tokyo.
# ID of each center is found in the Common Code Table C-11.
$id_center = 1; ############# Melbourne  (or could be 2?!)
#$id_center = 34;
#
# path of "ncdump" command
#$ncdump_path = "/home/argo/ArgoRT/ncdump";
#
# ========================================================================

if($#ARGV < 1)
{
	print << "END";
** insufficient arguments ** 
usage: command <ouput BUFR file> <input netCDF Core file> <input netCDF Bio file (optional)>
END
	exit 0;
}

########## read BUFR table ##########
#
#	Table file format: 
#		001003 i 0 0 3 Code WMO_Regional_number 
#	$a[0]	table_reference (ex. 022055 )
#	$a[1]	type of variable (i:integer, f:float, etc.)
#	$a[2]	scale 
#	$a[3]	reference value
#	$a[4]	data width (bits)
#	$a[5] 	unit (ex. Numeric, CCITT_IA5, Code_table, m/s, K, etc.)
#	$a[6]	element name (ex. Float_cycle_number ) 
#
#	$tab_s{$a[0]} = $a[2]; scale
#	$tab_r{$a[0]} = $a[3]; reference value
#	$tab_l{$a[0]} = $a[4]; length of the data (bits) 
#	$tab_n{$a[0]} = $a[6]; name 

$text = << "BUFR_TABLE_END";
001085 s 0 0 160 CCITT_IA5 Observing_platform_manufacturer's_model
001086 s 0 0 256 CCITT_IA5 Observing_platform_manufacturer's_serial_number
001087 i 0 0 23 Numeric WMO_Marine_observing_platform_extended_identifier
002032 i 0 0 2 Code Indicator_for_digitization
002036 i 0 0 2 Code Buoy_type
002148 i 0 0 5 Code Data_collection_and/or_location_system
002149 i 0 0 6 Code Type_of_data_buoy
004001 i 0 0 12 Year Year
004002 i 0 0 4 Month Month
004003 i 0 0 6 Day Day
004004 i 0 0 5 Hour Hour
004005 i 0 0 6 Minute Minute
005001 f 5 -9000000 25 Degree Latitude(high_accuracy)
006001 f 5 -18000000 26 Degree Longitude(high_accuracy)
007062 f 1 0 17 m Depth_below_sea/water_surface
007065 f -3 0 17 Pa Water_pressure
008034 i 0 0 4 Code Type_of_temperature/salinity_measurement
008080 i 0 0 6 Code Qualifier_for_GTSPP_quality_flag
022045 f 3 0 19 K Sea/water_temperature
022055 i 0 0 10 Numeric Float_cycle_number
022056 i 0 0 2 Code Direction_of_profile
022064 f 3 0 17 %m  Salinity
022067 i 0 0 10 Code Instrument_type_for_water_temperature/salinity_profile_measurement
022188 f 3 0 19 m_mol/kg Dissolved_oxygen
031002 i 0 0 16 Numeric Extended_delayed_descriptor_replication_factor
033050 i 0 0 4 Code Global_GTSPP_quality_flag
BUFR_TABLE_END

@bufr_table = split /\n/,$text;
foreach $value (@bufr_table)
{
	my @a = split /  */,$value;
	$tab_s{$a[0]} = $a[2];
	$tab_r{$a[0]} = $a[3];
	$tab_l{$a[0]} = $a[4];
	$tab_n{$a[0]} = $a[6];
}

$fn_out = shift @ARGV;
if(open OUTFILE, $fn_out)
{
	print "** BUFR output file: $fn_out already exists. \n";
	print "This program does not overwrite the file. \n";
	print "Process interrupted. \n";
	close OUTFILE;
	exit 0;
}

########## construct BUFR message section 4: data section ##########
# $bc: section 4 bit image character array
$bc = "";
$fn_core = shift @ARGV;
if($#ARGV > -1){
	$fn_bio = shift @ARGV;
}else{
	$fn_bio = "NA";
}
$add_fxy = &set_sec4sub($fn_core, $fn_bio);
$n_subset = 1;

# pad the tail of section 4 with "00..." 
$bc .= "0000000";
$len = length $bc;
$mod = $len % 8;
$len -= $mod;
$bc = substr($bc, 0, $len);
$len_sec4 = 4 + ((length $bc) / 8);
# put the head 4 octets of section 4 
$bc = &num2bitc($len_sec4, 24)."00000000".$bc;
# conversion into bit array 
$sec4 = pack ("B*", $bc);

########## construct BUFR message section 3 ##########
$len_sec3 = &set_sec3($add_fxy);

########## construct BUFR message section 0 ##########
$sec0 = "BUFR@@@@";
$len_total = 8 + 22 + $len_sec3 + $len_sec4 + 4;
if($len_total > 16777215)
{
	print "total BUFR length too long (>16,777,215) $len_total \n";
	print "BUFR not created";
	exit 0;
}
$bc = &num2bitc($len_total, 24);
$bc .= &num2bitc(4, 8);  # BUFR edition number = 4
substr($sec0, 4, 4) = pack ("B*", $bc);

########## construct BUFR message section 1 ##########
#	 length of the senction =22
$bc = &num2bitc(22, 24);
$bc .= &num2bitc(0, 8);  #4 BUFR master table = 0 (WMO standard) 
$bc .= &num2bitc($id_center, 16); #5-6 Generating center ID (Table C-11)
$bc .= &num2bitc(0, 16); #7-8 Sub-center ID (Table C-12), 0: No sub-center assumed 
$bc .= &num2bitc(0, 8);  #9 update sequence number, 0 for an origincal message
$bc .= &num2bitc(0, 8);  #10 No optional section 
$bc .= &num2bitc(31, 8); #11 Data category (Table A), 31: Oceanographic
$bc .= &num2bitc(4, 8);  #12 Data sub-category (Table C-13), 4: Float profile
$bc .= &num2bitc(0, 8);  #13 Local data sub-category
$bc .= &num2bitc(25, 8);  #14 Version number of master table 
$bc .= &num2bitc(0, 8);  #15 Version number of local table 
# date/time, most typical for the BUFR message contents  
@a = gmtime $juld1970;
$bc .= &num2bitc(($a[5] + 1900), 16);  #16-17 Year
$bc .= &num2bitc(($a[4] + 1), 8);  #18 Month
$bc .= &num2bitc($a[3], 8);  #19 Day 
$bc .= &num2bitc($a[2], 8);  #20 Hour
$bc .= &num2bitc($a[1], 8);  #21 Minute
$bc .= &num2bitc($a[0], 8);  #22 Second 
$sec1 = pack ("B*", $bc);

########## construct BUFR message section 5: End section ##########
$sec5 = "7777";

open FILE, ">$fn_out";
print FILE $sec0, $sec1, $sec3, $sec4, $sec5;
close FILE;

exit 0;


# ========================================================================
sub num2bitc
{
	my $x = $_[0];
	my $nbit = $_[1];
        my $mbit = $nbit % 8;
        my $noc = ($nbit - $mbit) / 8;
	my ($n, $y, $z, $c, $b);
	$z = "";
	for ($n=0; $n<=$noc; $n++)
	{
		$y = $x % 256;
		$c = pack ("C*", $y);
		$b = unpack ("B*", $c);
		$z = $b.$z;
		$x = ($x - $y) / 256;
	}
	return substr($z, ((length $z) - $nbit), $nbit);
}

# -----------------------------------------------------------------------------
sub value2bitc
{
	my $x;
	my $key = $_[0];
	my $val = $_[1];
	my $max = (2 ** $tab_l{$key}) - 1;   # $max (all bit on) means missing value 
	if($val eq "MISS"){
		$x = $max;
	}else{
		$x = int ($val * (10 ** $tab_s{$key}) - $tab_r{$key} + 0.001);
		if($x < 0 || $x > $max)	
		{
			$x = $max;
		}
	}
	my $y = &num2bitc($x, $tab_l{$key});
#	print "$key, $tab_l{$key}, $tab_s{$key}, $tab_r{$key}, $val, $x, $y, $tab_n{$key}\n";
	return $y;
}

# -----------------------------------------------------------------------------
sub cnv033050
{
	my $x = $_[0];
	$x = ord $x;
	my $z = 15; 			# missing value
	if($x >= 48 && $x < 57)	 	# "0":48, "9 (missing)":57
	{
		$z = $x - 48;
	}	
	return $z;
}

# -----------------------------------------------------------------------------
sub cnv008034
{
	# Temperature / salinity measurement qualifier
	my $v_scheme = $_[0];
	my $z = 15;   # missing value
	if($v_scheme =~ /Secondary sampling:/i){
		if($v_scheme =~ /averaged/i){
			$z = 0;                           # secondary sampling: averaged
		}elsif($v_scheme =~ /discrete/i){
			$z = 1;                           # secondary sampling: discrete
		}elsif($v_scheme =~ /mixed/i){
			$z = 2;                           # secondary sampling: mixed
		}
	}elsif($v_scheme =~ /Near-surface sampling:/i){
		if($v_scheme =~ /averaged/i){
			$z = 3;                           # near-surface sampling: averaged
		}elsif($v_scheme =~ /discrete/i){
			$z = 5;                           # near-surface sampling: discrete
		}elsif($v_scheme =~ /mixed/i){
			$z = 7;                           # near-surface sampling: mixed
		}
		if($v_scheme =~ /unpumped/i){
			$z += 1;                          # un-pumped
		}
	}
	return $z;
}

# -----------------------------------------------------------------------------
sub sec3each
{
	my $f = $_[0];
	my $y = $f % 1000;
	$f = ($f - $y) / 1000;
	my $x = $f % 100;
	$f = ($f - $x) / 100;
	return &num2bitc($f, 2).&num2bitc($x, 6).&num2bitc($y, 8);
}

# -----------------------------------------------------------------------------
sub chars2bitc
{
	my $i;
	my $y = "";
	my $key = $_[0];
	my $val = $_[1];
	if($val eq "MISS"){
		for ($i=0; $i<$tab_l{$key}; $i++)
		{
			$y .= "1";
		}
	}else{
		$y = unpack ("B*", $val);
		my $init = length $y;
		for ($i=$init; $i<$tab_l{$key}; $i+=8)
		{
			$y .= "00100000";
		}
	}
#	print "$val, $key, $tab_l{$key}, $y, $tab_n{$key}\n";
	return $y;
}

# -----------------------------------------------------------------------------
sub set_sec3
{
	my @fxys = ();
	my ($fxy);
	my $add_fxy = $_[0];
# 	$dc: section 3 bit image character array
	$dc = &num2bitc($n_subset, 16)."10000000";
	$dc .= &sec3each("315003");
	my @fxys = split /-/,$add_fxy;
	foreach $fxy (@fxys)
	{
		$dc .= &sec3each($fxy);
		print " additional template : ".$fxy."\n";
	}
	$len_sec3 = 4 + ((length $dc) / 8);
	$dc = &num2bitc($len_sec3, 24)."00000000".$dc;
	$sec3 = pack ("B*", $dc);
	return $len_sec3;
}

# ========================================================================
sub set_sec4sub
#	usage: &set_sec4sub($Core-filename, $Bio-filename);
{
my $FillValue = 99999.;


# Core-file
my $fn_core = $_[0];
@ncdump = ();
@ncdump = &get_ncdump($fn_core);
$n_prof = &get_ncdim("N_PROF", @ncdump);
$n_levels = &get_ncdim("N_LEVELS", @ncdump);

# Bio-file
my $fn_bio = $_[1];
my @bncdump = ();
if (-f $fn_bio){
	@bncdump = &get_ncdump($fn_bio);
	$bn_prof = &get_ncdim("N_PROF", @bncdump);
	$bn_levels = &get_ncdim("N_LEVELS", @bncdump);
	#
	# check the consistency between Core and Bio files
	#
	if($n_prof*$n_levels != $bn_prof*$bn_levels){
		print "** Dimensions differ : $fn_core and $fn_bio. \n";
		print " Core (N_PROF / N_LEVELS) : ".$n_prof." / ".$n_levels."\n";
		print " Bio  (N_PROF / N_LEVELS) : ".$bn_prof." / ".$bn_levels."\n";
		print "Process interrupted. \n";
		exit 0;
	}
#
	@tmps = ("PLATFORM_NUMBER", "CYCLE_NUMBER", "JULD", "LATITUDE", "LONGITUDE");
	foreach $tmp (@tmps){
		if(abs(&get1value($tmp, @ncdump) - &get1value($tmp, @bncdump)) > 1.e-5){
			print "** Different data : $fn_core and $fn_bio. \n";
			print " $tmp Core : ".&get1value($tmp, @ncdump)."\n";
			print " $tmp Bio  : ".&get1value($tmp, @bncdump)."\n";
			print "Process interrupted. \n";
			exit 0;
		}
	}
}

########## construct part of section 4 ##########
#
# 3-15-003 : Temperature and salinity profile observed by profile floats
#
# $bc: section 4 bit image character array

#	001087 - WMO Marine observing platfor extended identifier (0-7999999)
$bc .= &value2bitc("001087", &get1value("PLATFORM_NUMBER", @ncdump));

#	001085 - Observing platform manufactures model (20 characters) 
#	001086 - Observing platform manufactures serial number (32 characters) 
$xx = &get_chars("WMO_INST_TYPE", 4);
$bc .= &chars2bitc("001085", $xx);
$xx = &get_chars("FLOAT_SERIAL_NO", 32);
$bc .= &chars2bitc("001086", $xx);

#	002036 - Buoy type = 2: Sub-surfce float (code table 0 02 036)
$bc .= &value2bitc("002036", 2);

#	002148 - Data collection and/or location system (code table 0 02 148)
$xx = &get1value("POSITIONING_SYSTEM", @ncdump);
if (substr($xx, 0, 5) eq "ARGOS") 
{
	$bc .= &value2bitc("002148", 1);
}
elsif (substr($xx, 0, 3) eq "GPS")
{
	$bc .= &value2bitc("002148", 2);
}
elsif (substr($xx, 0, 7) eq "IRIDIUM")
{
	$bc .= &value2bitc("002148", 7);
}
else
{
	$bc .= &value2bitc("002148", 31); # missing value 
}

#	002149 - Type of data buoy = 26: Sub-surface ARGO float 
$bc .= &value2bitc("002149", 26);

#	022055 - Float cycle number 
$bc .= &value2bitc("022055", &get1value("CYCLE_NUMBER", @ncdump));

#	022056 - Direction of profile 
$xx = substr(&get1value("DIRECTION", @ncdump), 0, 1);
if ($xx eq "A") 
{
	$bc .= &value2bitc("022056", 0);
}
elsif ($xx eq "D") 
{
	$bc .= &value2bitc("022056", 1);
}
else
{
	$bc .= &value2bitc("022056", 3); # missing value
}

#	022067 - Instrument type for water temperature profile measurement
#		IxIxIx, common code table C-3 (code table 1770) 
$bc .= &value2bitc("022067", &get1value("WMO_INST_TYPE", @ncdump));

################## date and time
#
#	301011 - Date 
#		004001 - Year 
#		004002 - Month 
#		004003 - Day 
#	301012 - Time 
#		004004 - Hour
#		004005 - Minute 
$juld = &get1value("JULD", @ncdump);
if($juld == 999999.){
	@a = "MISS";
}else{
	$juld1970 = ($juld + 0.000001 - 7305) * 86400;
	@a = gmtime $juld1970;
	$a[5] += 1900;
	$a[4] += 1;
}
$bc .= &value2bitc("004001", $a[5]);
$bc .= &value2bitc("004002", $a[4]);
$bc .= &value2bitc("004003", $a[3]);
$bc .= &value2bitc("004004", $a[2]);
$bc .= &value2bitc("004005", $a[1]);

################## location and location_flag
#
#	301021 - Latitude and longitude (high accuracy) 
#	005001 - Latitude (high accuracy, scale 5)
#	006001 - Longitude (high accuracy, scale 5)
$xx = &get1value("LATITUDE", @ncdump);
if($xx == $FillValue){
	$xx = "MISS";
}else{
	$xx = int( ($xx + 90) * 100000 + 0.5) * 0.00001 - 90; 
}
$bc .= &value2bitc("005001", $xx);

$xx = &get1value("LONGITUDE", @ncdump);
if($xx == $FillValue){
	$xx = "MISS";
}else{
	$xx = int( ($xx + 180) * 100000 + 0.5) * 0.00001 -180; 
}
$bc .= &value2bitc("006001", $xx);

#	008080 - Qualifier for quality class, 20: position 
#	033050 - GTSPP quality class 
$bc .= &value2bitc("008080", 20);
$bc .= &value2bitc("033050", &cnv033050(substr(&get1value("POSITION_QC", @ncdump), 0, 1)));

################## profile data 
#
#	109000 - Replication of the following 9 descriptors
#		 Number of replication is specified by the next descriptor
#	031002 - Number of replication (0-65535)
#	007065 - Water pressure (0.0-13107.2 10000Pa)
#	008080 & 033050 - Quality flag for depth 
#	022045 - Subsurface sea temperature (scale 3) 
#	008080 & 033050 - Quality flag for temperature 
#	022064 - Salinity (scale 3) 
#	008080 & 033050 - Quality flag for salinity 
#

@v_scheme = &get_chars_array("VERTICAL_SAMPLING_SCHEME",256);

$bc .= &value2bitc("031002", $n_levels);

$n_params = &get_ncdim("N_PARAM", @ncdump);
%bfparam = ("PRES", 0, "TEMP", 0, "PSAL", 0);
@st_params = ();
@st_params = &get_values("STATION_PARAMETERS", @ncdump);
@params = ();
foreach $param (@st_params[0..$n_params-1])
{
	if(exists $bfparam{$param})
	{
		$n_params = push @params, $param; 
	}
}

for ($i=0; $i<$n_levels*$n_prof; $i++)
{
	@pp[$i] = $FillValue;
	@tt[$i] = $FillValue;
	@ss[$i] = $FillValue;
	@do[$i] = $FillValue;   # Dissolved oxygen
	@pq[$i] = 15;
	@tq[$i] = 15;
	@sq[$i] = 15;
	@dq[$i] = 15;   # Dissolved oxygen
}
$data_mode = substr(&get1value("DATA_MODE", @ncdump), 0, 1);
foreach $param (@params)
{
	if($data_mode eq "D" or $data_mode eq "A") 
	{
		$varid1 = $param."_ADJUSTED";
		$varid2 = $param."_ADJUSTED_QC";
	}
	else 
	{
		$varid1 = $param;
		$varid2 = $param."_QC";
	}

	@vv = &get_prof($varid1, @ncdump);
	@qq = &get_qcflag($varid2, @ncdump);
	if($param eq "PRES")
	{
		for ($i=0; $i<$n_levels*$n_prof; $i++)
		{
			if ($vv[$i] != $FillValue){
				$pp[$i] = int($vv[$i] * 10 + 0.5 ) * 1000;
			}
		}
		@pq = @qq;
	}
	elsif ($param eq "TEMP")
	{
		for ($i=0; $i<$n_levels*$n_prof; $i++)
		{
			if ($vv[$i] != $FillValue){
				$tt[$i] = int(($vv[$i] + 273.15) * 1000 + 0.5) * 0.001;
			}
		}
		@tq = @qq;
	}
	elsif ($param eq "PSAL")
	{
		for ($i=0; $i<$n_levels*$n_prof; $i++)
		{
			if ($vv[$i] != $FillValue){
				$ss[$i] = int($vv[$i] * 1000 + 0.5) * 0.001;
			}
		}
		@sq = @qq;
	}
}

# primary profile
for ($i=0; $i<$n_levels; $i++)
{
	$bc .= &value2bitc("007065", $pp[$i]);
	$bc .= &value2bitc("008080", 10);
	$bc .= &value2bitc("033050", &cnv033050($pq[$i]));
	$bc .= &value2bitc("022045", $tt[$i]);
	$bc .= &value2bitc("008080", 11);
	$bc .= &value2bitc("033050", &cnv033050($tq[$i]));
	$bc .= &value2bitc("022064", $ss[$i]);
	$bc .= &value2bitc("008080", 12);
	$bc .= &value2bitc("033050", &cnv033050($sq[$i]));
}

################## additional data
my $add_fxy = "";
#
#	3-06-017/018 : sub-surface temperature & salinity
#	
for ($i=1; $i<$n_prof; $i++)
{
	# check whether T/S data exist or not
	$nt = 0;
	$ns = 0;
	for ($j=0; $j<$n_levels; $j++)
	{
		if ($tt[$n_levels*$i+$j] != $FillValue)
		{
			$nt++;
		}
		if ($ss[$n_levels*$i+$j] != $FillValue)
		{
			$ns++;
		}
	}
#
	# sub-surface temperature & salinity (3-06-017 or 3-06-018)
	if ($nt > 0 || $ns > 0){
		$bc .= &value2bitc("002032", 0);   # Indicator for digitization
		$bc .= &value2bitc("008034", &cnv008034($v_scheme[$i]));   # Temperature / salinity measurement qualifier
		$bc .= &value2bitc("031002", $nt);
		for ($j=0; $j<$n_levels; $j++)
		{
			$nl=$n_levels*$i+$j;
			if ($tt[$nl] != $FillValue)
			{
				$bc .= &value2bitc("007065", $pp[$nl]);
				$bc .= &value2bitc("008080", 10);
				$bc .= &value2bitc("033050", &cnv033050($pq[$nl]));
				$bc .= &value2bitc("022045", $tt[$nl]);
				$bc .= &value2bitc("008080", 11);
				$bc .= &value2bitc("033050", &cnv033050($tq[$nl]));
				# sub-surface salinity (3-06-018 only)
				if ($ns > 0){
					$bc .= &value2bitc("022064", $ss[$nl]);
					$bc .= &value2bitc("008080", 12);
					$bc .= &value2bitc("033050", &cnv033050($sq[$nl]));
				}
			}

		}
		$bc .= &value2bitc("008034", 15);   # Temperature / salinity measurement qualifier (Cancel: set to missing)
		if ($ns > 0){
			$add_fxy .= "306018-";
		}else{
			$add_fxy .= "306017-";
		}
	}
}



################## additional data
#
#	3-06-037 : Dissolved oxygen profile data
#	
@bst_params = &get_values("STATION_PARAMETERS", @bncdump);
if(grep{$_ eq 'DOXY'} @bst_params){
	@vv = &get_prof("DOXY", @bncdump);
	@qq = &get_qcflag("DOXY_QC", @bncdump);
	for ($i=0; $i<$n_levels*$n_prof; $i++)
	{
		if ($vv[$i] != $FillValue){
			$do[$i] = $vv[$i];
		}
	}
	@dq = @qq;
#
	for ($i=0; $i<$n_prof; $i++)
	{
		# check whether doxy data exist or not
		$nd = 0;
		for ($j=0; $j<$n_levels; $j++)
		{
			if ($do[$n_levels*$i+$j] != $FillValue)
			{
				$nd++;
			}
		}
#
		# Dissolved oxygen profile data
		if ($nd > 0){
			$bc .= &value2bitc("031002", $nd);
			for ($j=0; $j<$n_levels; $j++)
			{
				$nl=$n_levels*$i+$j;
				if ($do[$nl] != $FillValue)
				{
					$bc .= &value2bitc("007062", "MISS");
					$bc .= &value2bitc("008080", "MISS");
					$bc .= &value2bitc("033050", "MISS");
					$bc .= &value2bitc("007065", $pp[$nl]);
					$bc .= &value2bitc("008080", 10);
					$bc .= &value2bitc("033050", &cnv033050($pq[$nl]));
					$bc .= &value2bitc("022188", $do[$nl]);
					$bc .= &value2bitc("008080", 16);
					$bc .= &value2bitc("033050", &cnv033050($dq[$nl]));
				}
			}
			$add_fxy .= "306037-";
		}
	} # $n_prof
}
return $add_fxy;
} # end set_sec4sub

# -----------------------------------------------------------------------------
sub get_ncdump
#	usage: &get_ncdump($filename);
{
	my $fname = $_[0];
	my $type = 'nul';
	my $v = '';
	my @line = (); 
	my @dump = ();

	@line = split /\n/,readpipe "ncdump $fname";
	foreach $_ (@line) {
		if(m/^dim/) {
			$type = 'dim';
		}
		elsif(m/^var/) {
			$type = 'var';
					push @dump, &get_ncdump_sub1($v);
					$v = '';
		}
		elsif(m/^dat/) {
			$type = 'dat';
		}
		else {
			if($type eq 'dim' || $type eq 'dat') {
				tr/\t=/  /;
				$v .= $_;
				if(m/;$/) {
					if($v =~ /^ VERTICAL_SAMPLING_SCHEME/){
						push @dump, &get_ncdump_sub2($v);
					}else{
						push @dump, &get_ncdump_sub1($v);
					}
					$v = '';
				}
			}
		}
	}
	return(@dump);
}

# -----------------------------------------------------------------------------
sub get_ncdump_sub1
{
	$_ = $_[0];
	s/,  */ /g;
	s/^  *//;
#	print "$_\n";
	return $_;
}

# -----------------------------------------------------------------------------
sub get_ncdump_sub2
{
	$_ = $_[0];
	s/",  */" /g;
	s/^  *//;
#	print "$_\n";
	return $_;
}

# -----------------------------------------------------------------------------
sub get_qcflag
{
#	usage: 	&get_qcflag($valiable_name, @dumped_result);
	my ($vname, @dump) = @_;
	my ($np, $nl, $i);
	my @a = ();
	my @line = (); 
	my @qq = ();

 	$nl = &get_ncdim("N_LEVELS", @dump);
	$np = &get_ncdim("N_PROF", @dump);

	foreach $v (@dump)
	{
		@a = split /  */,$v;
		if($a[0] eq $vname) {
			$v =~ s/"\s+"//g;
			$offset = index $v, '"';
			$offset++;
			for ($i=0; $i<$np*$nl; $i++) {
				$qq[$i] = substr ($v, $i + $offset, 1);
#				print "$vname $i $qq[$i]\n";
			}
		}
	}
	return @qq;
}

# -----------------------------------------------------------------------------
sub get_ncdim
{
#	usage: 	&get_ncdim($dimension_name, @dumped_result);
	my ($dname, @dump) = @_;
	my ($v, $return);
	my @a = ();
	foreach $v (@dump)
	{
		@a = split /  */,$v;
		if($a[0] eq $dname) {
			$return = $a[1];
		}
	}
	return $return;
}

# -----------------------------------------------------------------------------
sub get1value
{
#	usage: 	&get1value($valiable_name, @dumped_result);
	my ($vname, @dump) = @_;
	my (@a);
	@a = &get_values($vname, @dump);
	return shift @a;
}

# -----------------------------------------------------------------------------
sub get_chars
{
#	usage: 	&get_chars($valiable_name, $length);
	my $vname = $_[0];
	my $length = $_[1];
	my (@a, $return, $v, $offset);

	foreach $v (@ncdump)
	{
		@a = split /  */,$v;
		if($a[0] eq $vname) {
			$offset = index $v, '"';
			$offset++;
			$return = substr ($v, $offset, $length);
		}
	}
	return $return;
}

# -----------------------------------------------------------------------------
sub get_chars_array
{
#	separate strings with ["]
#	usage: 	&get_chars_array($valiable_name, $length);
	my $vname = $_[0];
	my $length = $_[1];
	my (@a, @return, $v, $offset, $len, $ioffset);

	foreach $v (@ncdump)
	{
		@a = split /  */,$v;
		if($a[0] eq $vname) {
			$len = length($v);
			$ioffset = 0;
			while ($ioffset < $len-$length){
				$offset = index $v, '"', $ioffset;
				$offset++;
				push @return, substr ($v, $offset, $length);
				$ioffset = ioffset + $offset + $length + 1;
			}
		}
	}
	return @return;
}

# -----------------------------------------------------------------------------
sub get_values
{
#	usage: 	&get_values($valiable_name, @dumped_result);
	my ($vname, @dump) = @_;
	my (@a, @return, $v, $offset);

	foreach $v (@dump)
	{
		@a = split /  */,$v;
		if($a[0] eq $vname) {
			$_ = $v;
			tr/";/  /;
			push @return, split /  */;
			shift @return;
		}
	}
	return @return;
}

# -----------------------------------------------------------------------------
sub get_prof
{
#	usage: 	&get_prof($valiable_name, @dumped_result);
	my ($vname, @dump) = @_;
	my @return = ();
	my @a = ();
	my $v;

	@a = get_values($vname, @dump);
	foreach $_ (@a)
	{
		s/_/99999./;
		push @return, $_;
	}
	return @return;
}
