#!/usr/bin/python

import xmlrpclib
import commands
import time
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

if(argc > 2):
 print 'Usage: # python %s <slice_name>' % argv[0]
 quit()

slice = argv[1]

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

twoweek = 1209600L

expires = long(time.time()) + twoweek

result = api.UpdateSlice(auth,slice,{'expires':expires})
