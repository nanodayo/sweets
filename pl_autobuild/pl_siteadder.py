#!/usr/bin/python

import xmlrpclib
import sys
import os

pwd = os.getcwd()
os.chdir('/etc/planetlab/')

import plc_config

os.chdir(pwd)

apiurl = 'https://' + plc_config.PLC_API_HOST + ':' + plc_config.PLC_API_PORT + plc_config.PLC_API_PATH
api = xmlrpclib.ServerProxy(apiurl)

auth = {}
auth['Username'] = 'root@nanodayo.org'
auth['AuthString'] = 'root'
auth['AuthMethod'] = 'password'
auth['role'] = 'admin'

result = api.AddSite(auth,{'name':'Site D011','url':'http://192.168.0.252/','enabled':True,'login_base':'d011','abbreviated_name':'D011'})
print result


