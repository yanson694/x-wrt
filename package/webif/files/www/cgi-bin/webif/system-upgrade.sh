#!/usr/bin/webif-page "-U /tmp -u 16384"
<?
. /usr/lib/webif/webif.sh

board_type=$(cat /proc/cpuinfo 2>/dev/null | sed 2,20d | cut -c16-)
machinfo=$(uname -a 2>/dev/null)
if $(echo "$machinfo" | grep -q "mips"); then
	if $(echo "$board_type" | grep -q "Atheros"); then
		target="atheros-2.6"
	elif $(echo "$board_type" | grep -q "WP54"); then
		target="adm5120-2.6"
	elif $(echo "$machinfo" | grep -q "2\.4"); then
		target="brcm"
	elif $(echo "$machinfo" | grep -q "2\.6"); then
		target="brcm"
	fi
elif $(echo "$machinfo" | grep -q " i[0-9]86 "); then
	target="x86-2.6"
elif $(echo "$machinfo" | grep -q " avr32 "); then
	target="avr32-2.6"
elif $(cat /proc/cpuinfo 2>/dev/null | grep -q "IXP4"); then
	target="ixp4xx-2.6"
fi

header "System" "Upgrade" "<img src=\"/images/upd.jpg\" alt=\"@TR<<Firmware Upgrade>>\" />&nbsp;@TR<<Firmware Upgrade>>" '' "$SCRIPT_NAME"

if [ "$target" = "brcm" ]; then
#####################################################################
do_upgrade() {
	echo "<br />Upgrading firmware, please wait ... <br />"
	# free some memory :)
	ps | grep -vE 'Command|init|\[[kbmj]|httpd|haserl|bin/sh|awk|kill|ps|webif' | awk '{ print $1 }' | xargs kill -KILL
	MEMFREE="$(awk 'BEGIN{ mem = 0 } ($1 == "MemFree:") || ($1 == "Cached:") {mem += int($2)} END{print mem}' /proc/meminfo)"
	empty "$ERASE_FS" || MTD_OPT="-e linux"
	if [ $(($MEMFREE)) -ge 4096 ]; then
		bstrip "$BOUNDARY" > /tmp/firmware.bin
		mtd $MTD_OPT -q -r write /tmp/firmware.bin linux
	else
		# Not enough memory for storing the firmware on tmpfs
		bstrip "$BOUNDARY" | mtd $MTD_OPT -q -q -r write - linux
	fi
	echo "@TR<<done>>."
}

#####################################################################
read_var() {
	NAME=""
	while :; do
		read LINE
		LINE="${LINE%%[^0-9A-Za-z]}"
		equal "$LINE" "$BOUNDARY" && read LINE
		empty "$NAME$LINE" && exit
		case "${LINE%%:*}" in
			Content-Disposition)
				NAME="${LINE##*; name=\"}"
				NAME="${NAME%%\"*}"
			;;
		esac
		empty "$LINE" && return
	done
}

#####################################################################
NOINPUT=1

#####################################################################
equal "$REQUEST_METHOD" "GET" && {
	cat <<EOF
<script type="text/javascript">
<!--
function statusupdate() {
	document.getElementById("form_submit").style.display = "none";
	document.getElementById("status_text").style.display = "inline";

	return true;
}
function printStatus() {
	document.write('<div style="display: none; font-size: 14pt; font-weight: bold;" id="status_text" />@TR<<Upgrading...>>&nbsp;</div>');
}
//-->
</script>

<form method="POST" name="upgrade" action="$SCRIPT_NAME" enctype="multipart/form-data" onSubmit="statusupdate()">
<table style="width: 90%; text-align: left;" border="0" cellpadding="2" cellspacing="2" align="center">
<tbody>
	<tr>
		<td>@TR<<Options>>:</td>
		<td>
			<input type="checkbox" name="erase_fs" value="1" />@TR<<Erase_JFFS2|Erase JFFS2 partition>>
		</td>
	</tr>
	<tr>
		<td>@TR<<Firmware_image|Firmware image to upload:>></td>
		<td>
			<input type="file" name="firmware" />
		</td>
	</tr>
	<tr>
		<td />
		<td>
			<script type="text/javascript">printStatus()</script>
			<input id="form_submit" type="submit" name="submit" value="@TR<<Upgrade>>" onClick="statusupdate()" />
		</td>
	</tr>
</tbody>
</table>
</form>
EOF
}
#####################################################################
equal "$REQUEST_METHOD" "POST" && {
	equal "${CONTENT_TYPE%%;*}" "multipart/form-data" || ERR=1
	BOUNDARY="${CONTENT_TYPE##*boundary=}"
	empty "$BOUNDARY" && ERR=1

	empty "$ERR" || {
		echo "Wrong data format"
		footer
		exit
	}
cat <<EOF
	<div style="margin: auto; text-align: left">
<pre>
EOF
	while :; do
		read_var
		empty "$NAME" && exit
		case "$NAME" in
			erase_fs)
				ERASE_FS=1
				bstrip "$BOUNDARY" > /dev/null
			;;
			firmware) do_upgrade;;
		esac
	done
cat <<EOF
	</div>
EOF
}
elif [ "$target" = "x86-2.6" ]; then
	if empty "$FORM_submit"; then
display_form <<EOF
start_form
field|@TR<<Firmware Image>>
upload|upgradefile
submit|upgrade| @TR<<Upgrade>> |
end_form
EOF
	else
		echo "<br />Upgrading firmware, please wait ... <br />"
		sysupgrade $upgradefile
		echo "@TR<<done>>."
	fi
else
	echo "<br />The ability to upgrade your platform has not been implemented.<br />"
fi

footer
?>
<!--
##WEBIF:name:System:900:Upgrade
-->
