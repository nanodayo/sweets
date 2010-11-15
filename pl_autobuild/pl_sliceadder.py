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

slice = 'pl_nanodayo'

#if (argc < 3):
# print 'Usage: # python %s <slice_name> <public_keyfile>' % argv[0]
# quit()

if(argc > 2):
 slice = argv[1]
 keyfile = argv[2]
elif(argc == 2):
 slice = argv[1]
 keyfile = slice + '.pub'
 if not os.path.exists(slice):
  commands.getstatusoutput('ssh-keygen -b 2048 -t rsa -f ' + slice)
else:
 print 'Usage: # python %s <slice_name> (<public_keyfile>)' % argv[0]
 quit()

f = open(keyfile, 'r')

for line in f:
	key = line
f.close

# user 
user = 'nanodayo@nanodayo.org'
first = 'Daisuke'
last = 'Matsui'
password = 'root'

description = 'Created via script'
slice_url = 'http://dummy.nanodayo.org'

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

nodes = []
result = api.GetNodes(auth,{},['hostname'])
for node in result:
 nodes.append(node['hostname'])

result = api.AddSlice(auth,{'name':slice, 'url':slice_url,'description':description})
print result
pid = api.AddPerson(auth, {'first_name':first,'last_name':last,'email':user,'password':password,'enabled':True})
print result
result = api.AddPersonToSlice(auth, user ,slice)
print result
result = api.AddPersonKey(auth, user, {'key_type':'ssh','key':key})
print result
result = api.AddSliceToNodes(auth, slice,nodes)
result = api.UpdatePerson(auth, pid, {'enabled':True})
print result