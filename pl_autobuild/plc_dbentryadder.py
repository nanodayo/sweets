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

dns = 'dns.nanodayo.org'

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

result = api.AddNodeNetworkSettingType(auth,{'category':'tunneling','min_role_id':30,'name':'tunnel','description':'tunnel server'})
result = api.AddNodeNetworkSettingType(auth,{'category':'Multihome','min_role_id':30,'name':'if_info','description':'Interface information'})
result = api.AddNodeNetworkSettingType(auth,{'category':'general','min_role_id':30,'name':'vlan','description':'VLAN ID(untagged)'})
result = api.AddNodeGroup(auth,{'name':'is_local','description':Not sharing node'})

result = api.AddNode(auth,1,{'boot_state':'dbg','hostname':dns, 'model':'','version':''})
result = api.AddNodeToNodeGroup(auth,dns,'is_local')
