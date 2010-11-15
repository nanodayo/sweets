#!/usr/bin/python

import xmlrpclib
import commands
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

if (argc < 1):
 print 'Usage: # python %s <peername>' % argv[0]
 quit()

commands.getoutput('tar -xzf \"%s\"' % argv[1])

tar = argv[1]
peername = tar.split('.')
dir = peername[0] + '/'
key = open(dir + peername[0] + '.gpg').read()
cacert = open(dir + peername[0] + '.crt').read()
peer_url = open(dir + peername[0]+'.url').read()

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

result = api.AddPeer(auth,{'key':key,'cacert':cacert,'peername':peername[0],'peer_url':peer_url})
