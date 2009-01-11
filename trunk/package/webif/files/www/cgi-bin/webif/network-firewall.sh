#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh
###################################################################
# Firewall configuration
#
# Description:
#	Firewall configuration.
#
# Author(s) [in order of work date]:
#	Original webif authors.
#	Travis Kemen	<kemen04@gmail.com>
# Major revisions:
#
# UCI variables referenced:
#
# Configuration files referenced:
#	firewall
#

#remove rule
if ! empty "$FORM_remove_vcfg"; then
	uci_remove "firewall" "$FORM_remove_vcfg"
fi

#Add new rules
if [ -n "$FORM_port_rule" ]; then
	validate <<EOF
string|FORM_name|@TR<<Name>>|nospaces|$FORM_name
ip|FORM_src_ip_rule|@TR<<Source IP Address>>||$FORM_src_ip_rule
ip|FORM_dest_ip_rule|@TR<<Destination IP Address>>||$FORM_dest_ip_rule
ports|FORM_port_rule|@TR<<Destination Port>>||$FORM_port_rule
EOF
	equal "$?" 0 && {
		uci_add "firewall" "rule" "$FORM_name"; add_rule_cfg="$CONFIG_SECTION"
		uci_set "firewall" "$add_rule_cfg" "src" "wan"
		uci_set "firewall" "$add_rule_cfg" "proto" "$FORM_protocol_rule"
		uci_set "firewall" "$add_rule_cfg" "src_ip" "$FORM_src_ip_rule"
		uci_set "firewall" "$add_rule_cfg" "dest_ip" "$FORM_dest_ip_rule"
		uci_set "firewall" "$add_rule_cfg" "dest_port" "$FORM_port_rule"
		uci_set "firewall" "$add_rule_cfg" "target" "ACCEPT"
		unset FORM_port_rule FORM_dest_ip_rule FORM_src_ip_rule FORM_protocol_rule FORM_name
	}
fi
if [ -n "$FORM_dest_ip_redirect" ]; then
	validate <<EOF
string|FORM_name_redirect|@TR<<Name>>|nospaces|$FORM_name_redirect
ip|FORM_src_ip_redirect|@TR<<Source IP Address>>||$FORM_src_ip_redirect
ports|FORM_src_dport_redirect|@TR<<Destination Port>>|required|$FORM_src_dport_redirect
ip|FORM_dest_ip_redirect|@TR<<To IP Address>>|required|$FORM_dest_ip_redirect
ports|FORM_dest_port_redirect|@TR<<To Port>>||$FORM_dest_port_redirect
EOF
	equal "$?" 0 && {
		uci_add "firewall" "redirect" "$FORM_name_redirect"; add_redirect_cfg="$CONFIG_SECTION"
		uci_set "firewall" "$add_redirect_cfg" "src" "wan"
		uci_set "firewall" "$add_redirect_cfg" "proto" "$FORM_protocol_redirect"
		uci_set "firewall" "$add_redirect_cfg" "src_ip" "$FORM_src_ip_redirect"
		uci_set "firewall" "$add_redirect_cfg" "src_dport" "$FORM_src_dport_redirect"
		uci_set "firewall" "$add_redirect_cfg" "dest_ip" "$FORM_dest_ip_redirect"
		[ "$FORM_dest_port_redirect" = "" ] && FORM_dest_port_redirect="$FORM_src_dport_redirect"
		uci_set "firewall" "$add_redirect_cfg" "dest_port" "$FORM_dest_port_redirect"
		unset FORM_dest_port_redirect FORM_dest_ip_redirect FORM_src_dport_redirect FORM_src_ip_redirect FORM_protocol_redirect FORM_name_redirect
	}
fi
if [ -n "$FORM_add_rule_add" ]; then
	uci_add "firewall" "forwarding" ""; add_foreward_cfg="$CONFIG_SECTION"
	uci_set firewall "$add_foreward_cfg" src "$FORM_src_add"
	uci_set firewall "$add_foreward_cfg" dest "$FORM_dest_add"
fi
config_cb() {
	local cfg_type="$1"
	local cfg_name="$2"

	case "$cfg_type" in
		forwarding)
			append forwarding_cfgs "$cfg_name"
		;;
		zone)
			append zone_cfgs "$cfg_name" "$N"
		;;
		rule)
			append rule_cfgs "$cfg_name" "$N"
		;;
		redirect)
			append redirect_cfgs "$cfg_name" "$N"
		;;
		interface)
			if [ "$cfg_name" != "loopback" ]; then
				append networks "option|$cfg_name" "$N"
			fi
		;;
	esac
}
cur_color="odd"
get_tr() {
	if equal "$cur_color" "odd"; then
		cur_color="even"
		tr="string|<tr>"
	else
		cur_color="odd"
		tr="string|<tr class=\"odd\">"
	fi
}

uci_load firewall
uci_load network
append forms "start_form|@TR<<Forwarding Configuration>>" "$N"
for zone in $forwarding_cfgs; do
	eval FORM_remove=\$FORM_remove_rule_$zone
	if [ "$FORM_remove" != "" ]; then
		uci_remove "firewall" "$zone"
	fi
	if [ "$FORM_submit" = "" -o "$add_foreward_cfg" = "$zone" ]; then
		config_get FORM_src $zone src
		config_get FORM_dest $zone dest
	else
		eval FORM_src="\$FORM_src_$zone"
		eval FORM_dest="\$FORM_dest_$zone"
		uci_set firewall "$zone" src "$FORM_src"
		uci_set firewall "$zone" dest "$FORM_dest"
	fi
	if [ "$FORM_remove" = "" ]; then
		form="field|@TR<<Allow traffic originating from>>
			select|src_${zone}|$FORM_src
			$networks
			string|@TR<<to>>
			select|dest_${zone}|$FORM_dest
			$networks
			submit|remove_rule_${zone}|@TR<<Remove Rule>>"
		append forms "$form" "$N"
	fi
done
form="field|@TR<<Allow traffic originating from>>
	select|src_add
	$networks
	string|@TR<<to>>
	select|dest_add
	$networks
	submit|add_rule_add|@TR<<Add Rule>>
	end_form"
append forms "$form" "$N"

get_tr
form="string|<div class=\"settings\">
	string|<h3><strong>@TR<<Incoming Ports>></strong></h3>
	string|<table style=\"width: 90%; margin-left: 2.5em; text-align: left; font-size: 0.8em;\" border=\"0\" cellpadding=\"3\" cellspacing=\"2\" summary=\"@TR<<Incomimg Ports>>\">
	$tr
	string|<th>@TR<<Name>></th>
	string|<th>@TR<<Protocol>></th>
	string|<th>@TR<<Source IP>></th>
	string|<th>@TR<<Destination IP>></th>
	string|<th>@TR<<Port>></th>
	string|</tr>"
append forms "$form" "$N"
for rule in $rule_cfgs; do
	if [ "$FORM_submit" = "" -o "$add_rule_cfg" = "$rule" ]; then
		config_get FORM_protocol $rule proto
		config_get FORM_src_ip $rule src_ip
		config_get FORM_dest_ip $rule dest_ip
		config_get FORM_port $rule dest_port
	else
		eval FORM_protocol="\$FORM_protocol_$rule"
		eval FORM_src_ip="\$FORM_src_ip_$rule"
		eval FORM_dest_ip="\$FORM_dest_ip_$rule"
		eval FORM_port="\$FORM_port_$rule"
		validate <<EOF
ip|FORM_src_ip|@TR<<Source IP Address>>||$FORM_src_ip
ip|FORM_dest_ip|@TR<<Destination IP Address>>||$FORM_dest_ip
ports|FORM_port|@TR<<Destination Port>>||$FORM_port
EOF
		equal "$?" 0 && {
			uci_set firewall "$rule" "proto" "$FORM_protocol"
			uci_set firewall "$rule" "src_ip" "$FORM_src_ip"
			uci_set firewall "$rule" "dest_ip" "$FORM_dest_ip"
			uci_set firewall "$rule" "dest_port" "$FORM_port"
		}
	fi

	echo "$rule" |grep -q "cfg*****" && name="" || name="$rule"
	get_tr
	form="$tr
		string|<td>$name</td>
		string|<td>
		select|protocol_$rule|$FORM_protocol
		option|tcp|TCP
		option|udp|UDP
		option|tcpudp|Both
		string|</td>
		string|<td>
		text|src_ip_$rule|$FORM_src_ip
		string|</td>
		string|<td>
		text|dest_ip_$rule|$FORM_dest_ip
		string|</td>
		string|<td>
		text|port_$rule|$FORM_port
		string|</td>
		string|<td>
		string|<a href=\"$SCRIPT_NAME?remove_vcfg=$rule\">@TR<<Remove Rule>></a>
		string|</td>
		string|</tr>"
	append forms "$form" "$N"
done
get_tr
form="$tr
	string|<td>
	text|name|$FORM_name
	string|</td>
	string|<td>
	select|protocol_rule|$FORM_protocol_rule
	option|tcp|TCP
	option|udp|UDP
	option|tcpudp|Both
	string|</td>
	string|<td>
	text|src_ip_rule|$FORM_src_ip_rule
	string|</td>
	string|<td>
	text|dest_ip_rule|$FORM_dest_ip_rule
	string|</td>
	string|<td>
	text|port_rule|$FORM_port_rule
	string|</td>
	string|<td>
	string|&nbsp;
	string|</td>
	string|</tr>
	string|</table></div>"
append forms "$form" "$N"

#PORT Forwarding
cur_color="odd"
get_tr
form="string|<div class=\"settings\">
	string|<h3><strong>@TR<<Port Forwarding>></strong></h3>
	string|<table style=\"width: 90%; margin-left: 2.5em; text-align: left; font-size: 0.8em;\" border=\"0\" cellpadding=\"3\" cellspacing=\"2\" summary=\"@TR<<Port Forwarding>>\">
	$tr
	string|<th>@TR<<Name>></th>
	string|<th>@TR<<Protocol>></th>
	string|<th>@TR<<Source IP>></th>
	string|<th>@TR<<Destination Port>></th>
	string|<th>@TR<<To IP Address>></th>
	string|<th>@TR<<To Port>></th>
	string|</tr>"
append forms "$form" "$N"

for rule in $redirect_cfgs; do
	if [ "$FORM_submit" = "" -o "$add_redirect_cfg" = "$rule" ]; then
		config_get FORM_protocol $rule proto
		config_get FORM_src_ip $rule src_ip
		config_get FORM_dest_ip $rule dest_ip
		config_get FORM_src_dport $rule src_dport
		config_get FORM_dest_port $rule dest_port
	else
		eval FORM_protocol="\$FORM_protocol_$rule"
		eval FORM_src_ip="\$FORM_src_ip_$rule"
		eval FORM_dest_ip="\$FORM_dest_ip_$rule"
		eval FORM_dest_port="\$FORM_dest_port_$rule"
		eval FORM_src_dport="\$FORM_src_dport_$rule"
		validate <<EOF
ip|FORM_src_ip_rule|@TR<<Source IP Address>>||$FORM_src_ip_rule
ip|FORM_dest_ip_rule|@TR<<Destination IP Address>>||$FORM_dest_ip_rule
ports|FORM_src_dport|@TR<<Destination Port>>|required|$FORM_src_dport
ip|FORM_dest_ip|@TR<<To IP>>|required|$FORM_dest_ip
ports|FORM_dest_dport|@TR<<To Port>>||$FORM_dest_dport
EOF
		equal "$?" 0 && {
			uci_set firewall "$rule" "proto" "$FORM_protocol"
			uci_set firewall "$rule" "src_ip" "$FORM_src_ip"
			uci_set firewall "$rule" "dest_ip" "$FORM_dest_ip"
			uci_set firewall "$rule" "src_dport" "$FORM_src_dport"
			[ "$FORM_dest_port" = "" ] && FORM_dest_port="$FORM_src_dport"
			uci_set firewall "$rule" "dest_port" "$FORM_dest_port"
		}
	fi

	echo "$rule" |grep -q "cfg*****" && name="" || name="$rule"
	get_tr
	form="$tr
		string|<td>$name</td>
		string|<td>
		select|protocol_$rule|$FORM_protocol
		option|tcp|TCP
		option|udp|UDP
		option|tcpudp|Both
		string|</td>
		string|<td>
		text|src_ip_$rule|$FORM_src_ip
		string|</td>
		string|<td>
		text|src_dport_$rule|$FORM_src_dport
		string|</td>
		string|<td>
		text|dest_ip_$rule|$FORM_dest_ip
		string|</td>
		string|<td>
		text|dest_port_$rule|$FORM_dest_port
		string|</td>
		string|<td>
		string|<a href=\"$SCRIPT_NAME?remove_vcfg=$rule\">@TR<<Remove Rule>></a>
		string|</td>
		string|</tr>"
	append forms "$form" "$N"
done
get_tr
form="$tr
	string|<td>
	text|name_redirect|$FORM_name_redirect
	string|</td>
	string|<td>
	select|protocol_redirect|$FORM_protocol_redirect
	option|tcp|TCP
	option|udp|UDP
	option|tcpudp|Both
	string|</td>
	string|<td>
	text|src_ip_redirect|$FORM_src_ip_redirect
	string|</td>
	string|<td>
	text|src_dport_redirect|$FORM_src_dport_redirect
	string|</td>
	string|<td>
	text|dest_ip_redirect|$FORM_dest_ip_redirect
	string|</td>
	string|<td>
	text|dest_port_redirect|$FORM_dest_port_redirect
	string|</td>
	string|<td>
	string|&nbsp;
	string|</td>
	string|</tr>
	string|</table></div>"
append forms "$form" "$N"



header "Network" "Firewall" "@TR<<Firewall>>" 'onload="modechange()"' "$SCRIPT_NAME"
#####################################################################
# modechange script
#
cat <<EOF
<script type="text/javascript" src="/webif.js"></script>
<script type="text/javascript">
<!--
function modechange()
{
	var v;
	$js

	hide('save');
	show('save');
}
-->
</script>

EOF

display_form <<EOF
onchange|modechange
$validate_error
$forms
EOF

footer ?>
<!--
##WEBIF:name:Network:415:Firewall
-->
