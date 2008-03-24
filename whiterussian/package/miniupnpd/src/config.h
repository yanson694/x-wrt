/* MiniUPnP Project
 * http://miniupnp.free.fr/ or http://miniupnp.tuxfamily.org/
 * (c) 2006-2008 Thomas Bernard
 * generated by ./genconfig.sh on Sun Mar 23 21:10:15 CET 2008 */
#ifndef __CONFIG_H__
#define __CONFIG_H__

#define UPNP_VERSION	"20070827"
#define USE_NETFILTER 1
#define OS_NAME		"OpenWrt"
#define OS_VERSION	"White Russian-0.9"
#define OS_URL		"http://openwrt.org/"

/* syslog facility to be used by miniupnpd */
#define LOG_MINIUPNPD		 LOG_DAEMON

/* Uncomment the following line to allow miniupnpd to be
 * controlled by miniupnpdctl */
#define USE_MINIUPNPDCTL

/* Comment the following line to disable NAT-PMP operations */
#define ENABLE_NATPMP

/* Uncomment the following line to enable generation of
 * filter rules with pf */
/*#define PF_ENABLE_FILTER_RULES*/

/* Uncomment the following line to enable caching of results of
 * the getifstats() function */
/*#define ENABLE_GETIFSTATS_CACHING*/
/* The cache duration is indicated in seconds */
#define GETIFSTATS_CACHING_DURATION 2

/* Uncomment the following line to enable multiple external ip support */
#define MULTIPLE_EXTERNAL_IP

/* Comment the following line to use home made daemonize() func instead
 * of BSD daemon() */
#define USE_DAEMON

/* Uncomment the following line to enable lease file support */
/*#define ENABLE_LEASEFILE*/

/* Define one or none of the two following macros in order to make some
 * clients happy. It will change the XML Root Description of the IGD.
 * Enabling the Layer3Forwarding Service seems to be the more compatible
 * option. */
/*#define HAS_DUMMY_SERVICE*/
#define ENABLE_L3F_SERVICE

/* Experimental UPnP Events support. */
/*#define ENABLE_EVENTS*/

#endif
