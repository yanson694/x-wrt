#!/usr/bin/webif-page
<?
#########################################
# Applications AirCrack
#
# Author(s) [in order of work date]:
#        Dmytro Dykhman <dmytro@iroot.ca>
#
. /usr/lib/webif/functions.sh
. /lib/config/uci.sh
. /www/cgi-bin/webif/applications-shell.sh

echo "$HEADER"

if ! empty "$FORM_package"; then

	App_package_install "AirCrack" "" "aircrack-ng"
	
	if  is_package_installed "aircrack-ng" && is_package_installed "libpthread" ; then 
	mkdir /wep 2> /dev/null
	##### Make config file

	if [ ! -s "/etc/config/app.aircrack" ] ; then 
	echo "config aircrack set
	option path	'/wep'
	option ivs	'checked'
	option boot	''" > /etc/config/app.aircrack
	fi
	echo_install_complete
	fi
exit
fi

if ! empty "$FORM_remove"; then
	App_package_remove "AirCrack" "app.aircrack" "aircrack-ng" "libpthread"
	rmdir /wep 2> /dev/null
exit
fi

if  is_package_installed "aircrack-ng" && is_package_installed "libpthread" ; then 

	cat <<EOF
	$HTMLHEAD</head><body bgcolor="#eceeec">
	<div id="mainmenu"><ul>
	<li><a href="$SCRIPT_NAME">Status</a></li>
	<li class="separator">-</li>
	<li><a href="$SCRIPT_NAME?page=aircrack">AirCrack</a></li>
	<li><a href="$SCRIPT_NAME?page=airodump">AiroDump</a></li>
	<li><a href="$SCRIPT_NAME?page=airoplay">AiroPlay</a></li>
	</ul></div><br/>
EOF
	######## Read config
	uci_load "app.aircrack"
	CFG_PATH="$CONFIG_set_path"
	CFG_CHANNEL="$CONFIG_set_channel"
	CFG_BOOT="$CONFIG_set_boot"
	CFG_IVS="$CONFIG_set_ivs"
	if equal $CFG_IVS "checked" ; then hIVS="--ivs" ; fi

	######## Run airodump
	if ! empty "$FORM_run_airodump"; then
	APP_Refresh_Page $SCRIPT_NAME?page=airodump "<br/>Starting AiroDump ...</br/>"
	killall -q airodump-ng 2> /dev/null
	wlc monitor 1
	airodump-ng $hIVS -w $CFG_PATH/key prism0 2> /dev/null
	exit
	fi

	######## Stop airodump
	if ! empty "$FORM_stop_airodump"; then
	echo "<META http-equiv="refresh" content='3;URL=$SCRIPT_NAME?page=airodump'>"
	echo "<br/>Stopping AiroDump ..."
	killall -q airodump-ng
	exit
	fi

	######## Save AirCrack
	if ! empty "$FORM_save_aircrack"; then
	echo "<META http-equiv="refresh" content='2;URL=$SCRIPT_NAME?page=$FORM_page'>"
	echo "<br/>saving...."

	uci_set "app.aircrack" "set" "path" "$FORM_airpath"

	### If checkbox on startup
	if ! empty "$FORM_chkstartup"; then
		uci_set "app.aircrack" "set" "boot" "checked"

		if  [ -s "/etc/init.d/aircrack" ]  ; then rm /etc/init.d/aircrack ; fi
	
		echo "#!/bin/sh
START=95
wlc monitor 1
airodump-ng $hIVS -w $CFG_PATH/key prism0" > /etc/init.d/aircrack

		ln -s /etc/init.d/aircrack /etc/rc.d/S95aircrack
		chmod 755 /etc/init.d/aircrack
	else 	### else
		uci_set "app.aircrack" "set" "boot" ""
		if [ -s "/etc/init.d/aircrack" ] ; then rm /etc/init.d/aircrack ; rm /etc/rc.d/S50aircrack; fi
	fi 	### end if checkbox on startup

	if ! empty "$FORM_chkivs"; then
		uci_set "app.aircrack" "set" "ivs" "checked"
	else uci_set "app.aircrack" "set" "ivs" "" ; fi

	uci_commit "app.aircrack"

	exit
	fi 

if [ "$FORM_page" = "aircrack" ]; then
		echo "in developemnt..."
elif [ "$FORM_page" = "airodump" ]; then

	####### Check if airodump is running
	if [ $(ps ax | grep -c airodump-ng) = "1" ] ; then

	cat <<EOF
	<form method="post" action='$SCRIPT_NAME'>
	<div class=warning>AiroDump is not running</div>&nbsp;&nbsp;<input type="submit" name="run_airodump" value="Run AiroDump" /><br/>
	</form><br/>
EOF
	else echo "<form method="post" action='$SCRIPT_NAME'><font color="#33CC00">AiroDump is succesfully started</font>&nbsp;&nbsp;<input type="submit" name="stop_airodump" value='Stop AiroDump' /></form><br/><br/>"
	fi

	cat <<EOF
	<strong>AiroDump Configuration</strong><br/>
	<br/><form action='$SCRIPT_NAME' method='post'>
	<table width="100%" border="0" cellspacing="1">
	<tr><td colspan="2" height="1"  bgcolor="#333333"></td></tr>
	<tr><td width="200"><a href="#" rel="b1">Storage Path</a></td><td><input name="airpath" type="text" value="$CFG_PATH" /></td></tr>
	<tr><td width="200"><a href="#" rel="b2">Channel</a></td><td><input name="airchannel" type="text" value="$CFG_CHANNEL" /></td></tr>
	<tr><td>&nbsp;</td><td><input type="checkbox" name="chkivs" $CFG_IVS />&nbsp;Save only captured IVs</td></tr>	
	<tr><td>&nbsp;</td><td><input type="checkbox" name="chkstartup" $CFG_BOOT />&nbsp;Run on boot</td></tr>
	<tr><td colspan="2" height="1" bgcolor="#333333"></td></tr>	
	<tr><td>&nbsp;</td><td>&nbsp;</td></tr>
	<tr><td>&nbsp;</td><td><input name="page" type="hidden" value="$FORM_page" /><input type="submit" style='border: 1px solid #000000;' name="save_aircrack" value="Save" /></td>
	</tr></table></form>
EOF
	TIP 0 "Path where airodump-ng will store IVS."
	TIP 0 "Set specific channel to scan. [nothing = all]"

elif [ "$FORM_page" = "airoplay" ]; then
	echo "in developemnt..."
else

	echo "<center><table width="85%" border="0" cellspacing="1" bgcolor="#000000">"

	if [ "$FORM_page" = "showstatus" ]; then
		echo "<tr><td bgcolor="#FFFFFF"><pre><font size=2>$(grep '' < $CFG_PATH/$FORM_file.txt)</font></pre></td></tr>"
	elif [ "$FORM_page" = "deletestatus" ]; then
		APP_Refresh_Page $SCRIPT_NAME "<br/>Deleting $FORM_file ...</br/>"
		rm $CFG_PATH/$FORM_file.txt 
		rm $CFG_PATH/$FORM_file.ivs
	else
		ls -a $CFG_PATH | grep ".txt" | sed -e s/'.txt'//g | awk '{ print $1 }' | while read output;
		do
		echo "<tr bgcolor='#FFFFFF'><td width='80%'>&nbsp;<a href='$SCRIPT_NAME?page=showstatus&file=$output'>$output</a></td><td><center><a href='$SCRIPT_NAME?page=deletestatus&file=$output'>Delete</a></center></td></tr>"
		done
		
	fi
	echo "</table></center>"
fi
echo "<br/></body></html>"
fi
?>