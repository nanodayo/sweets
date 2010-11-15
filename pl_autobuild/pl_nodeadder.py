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

mac = ''
ifname = ''
is_exp = False

if (argc < 4):
 print 'Usage: # python %s -n <node> -a <ipaddr> (-m <mac> -i <ifname> -e)' % argv[0]
 quit()

# argv parsing
acount = 0
for argv_tmp in argv:
 if argv_tmp == '-n':
  acount = acount + 1
  node = argv[acount]
 elif argv_tmp == '-a':
  acount = acount + 1
  ipaddr = argv[acount]
 elif argv_tmp == '-m':
  acount = acount + 1
  mac = argv[acount]
 elif argv_tmp == '-i':
  acount = acount + 1
  ifname = argv[acount]
 elif argv_tmp == '-e':
  acount = acount + 1
  is_exp = True
 else:
  acount = acount + 1

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

result = api.AddNode(auth,'pl',{'boot_state':'rins','hostname':node, 'model':'','version':''})
#print result
nid = api.AddNodeNetwork(auth,node,{'method':'dhcp','ip':ipaddr,'hostname':node,'type':'ipv4','mac':mac})
result = api.AddNodeNetworkSetting(auth,nid,'tunnel','none')
if is_exp:
 result = api.AddNodeNetworkSetting(auth,nid,'if_info','experiment')
else:
 result = api.AddNodeNetworkSetting(auth,nid,'if_info','manage')

if ifname:
 result = api.AddNodeNetworkSetting(auth,nid,'ifname',ifname)

result = api.GenerateNodeConfFile(auth,node,True)
print result
