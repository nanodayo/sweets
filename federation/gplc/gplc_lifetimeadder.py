#!/usr/bin/python

import getpass
import xmlrpclib
api = xmlrpclib.ServerProxy('https://www.planet-lab.org:443/PLCAPI/')

if (argc < 3):
 print 'Usage: # python %s <node> <expire>' % argv[0]
 quit()

node = argv[1]
expire = argv[2]

auth = {}
auth['Username'] = 'nanodayo@jaist.ac.jp'
auth['AuthString'] = getpass.getpass('input your PLC account\'s password -> ')
auth['AuthMethod'] = 'password'
auth['role'] = 'user'

auth_check = 0

while auth_check != 1:
 auth_check = api.AuthCheck(auth)
 if(auth_check != 1):
  auth['AuthString'] = getpass.getpass('input your PLC account\'s password -> ')


api.AddNodeTag(auth,node,'lifetime',expire)

