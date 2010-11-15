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

# arg check
argv = sys.argv
argc = len(argv)

if (argc < 5):
 print 'Usage: # python %s <flag> <peer> <node> <newip> <ifname> <vlan>' % argv[0]
 quit()

flag = argv[1]
#peer = argv[2]
node = argv[3]
newip = argv[4]
ifname = argv[5]
vlan = argv[6]

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

if flag == '-g':
 peer = argv[2]
elif flag == '-l':
 peer = 'none'

nid_tmp = api.GetNodes(auth,node,['nodenetwork_ids'])
print 'nid_tmp is %s' % nid_tmp
nids = nid_tmp[0]['nodenetwork_ids']
print 'nid is %s' % nids
for nid in nid_tmp[0]['nodenetwork_ids']:
 tunnel_id_tmp = api.GetNodeNetworks(auth, nid,['nodenetwork_setting_ids'])
 for nsetting_id in tunnel_id_tmp[0]['nodenetwork_setting_ids']:
  print 'nsetting_id is %s' % nsetting_id
  result = api.GetNodeNetworkSettings(auth,nsetting_id,['name','value'])
  print 'result[0][name] is %s' % result[0]['name']
  print 'result[0][value] is %s' % result[0]['value']
  if result[0]['name'] == 'ifname' and result[0]['value'] == ifname:
   print 'interface name is %s' % ifname
   ex_nid = nid
  elif(result[0]['name'] == 'vlan'):
   vlan_id = nsetting_id
#  if result[0]['name'] == 'if_info' and result[0]['value'] == 'manage':
#   print 'skipping manage interface'
#  elif result[0]['name'] == 'if_info' and result[0]['value'] == 'experiment':
#   ex_nid = nid
  elif(result[0]['name'] == 'tunnel' and flag == '-g'):
   tunnel_id = nsetting_id
  elif(result[0]['name'] == 'tunnel' and flag == '-l'):
   tunnel_id = nsetting_id

api.UpdateNodeNetworkSetting(auth, vlan_id ,vlan)
api.UpdateNodeNetworkSetting(auth, tunnel_id ,peer)
api.UpdateNodeNetwork(auth, ex_nid,{'ip':newip})
