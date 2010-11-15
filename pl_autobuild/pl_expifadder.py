#!/usr/bin/python

import xmlrpclib
import sys
import os

pwd = os.getcwd()
os.chdir('/etc/planetlab/')

import plc_config

os.chdir(pwd)

apiurl = 'https://' + plc_config.PLC_API_HOST + ':' + str(plc_config.PLC_API_PORT) + plc_config.PLC_API_PATH
api = xmlrpclib.ServerProxy(apiurl)

argv = sys.argv
argc = len(argv)

node = ''
ipaddr = ''
mac = ''
name = ''
if_name = ''
vlan = ''
is_manage = False

if (argc < 4):
 print 'Usage: # python %s -n <node> -a <ipaddr> (-m <mac> -h <name> -i <ifname> -mg)' % argv[0]
 quit()

# argv parsing
acount = 0
for argv_tmp in argv:
 if argv_tmp == '-h':
  acount = acount + 1
  name = argv[acount]
 elif argv_tmp == '-a':
  acount = acount + 1
  ipaddr = argv[acount]
 elif argv_tmp == '-n':
  acount = acount + 1
  node = argv[acount]
 elif argv_tmp == '-m':
  acount = acount + 1
  mac = argv[acount]
 elif argv_tmp == '-i':
  acount = acount + 1
  ifname = argv[acount]
 elif argv_tmp == '-v':
  acount = acount + 1
  vlan = argv[acount]
 elif argv_tmp == '-mg':
  acount = acount + 1
  is_manage = True
 else:
  acount = acount + 1

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

#node = api.GetNodes(auth,node)
nid = api.AddNodeNetwork(auth,node,{'method':'dhcp','ip':ipaddr,'hostname':name,'type':'ipv4','mac':mac})
result = api.AddNodeNetworkSetting(auth,nid,'tunnel','none')
if is_manage:
 result = api.AddNodeNetworkSetting(auth,nid,'if_info','manage')
else:
 result = api.AddNodeNetworkSetting(auth,nid,'if_info','experiment')

result = api.AddNodeNetworkSetting(auth,nid,'vlan',vlan)
result = api.AddNodeNetworkSetting(auth,nid,'ifname',ifname)
