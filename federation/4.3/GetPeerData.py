#
# Thierry Parmentelat - INRIA
# 
# $Id: GetPeerData.py 14587 2009-07-19 13:18:50Z thierry $
# $URL: http://svn.planet-lab.org/svn/PLCAPI/tags/PLCAPI-4.3-30/PLC/Methods/GetPeerData.py $

import time

from PLC.Faults import *
from PLC.Method import Method
from PLC.Parameter import Parameter, Mixed
from PLC.Auth import Auth

from PLC.Peers import Peer, Peers

from PLC.Sites import Site, Sites
from PLC.Keys import Key, Keys
from PLC.Nodes import Node, Nodes
from PLC.Persons import Person, Persons
from PLC.Slices import Slice, Slices
from PLC.SliceTags import SliceTags

# added by nanodayo
from PLC.NodeTags import NodeTag, NodeTags

class GetPeerData(Method):
    """
    Returns lists of local objects that a peer should cache in its
    database as foreign objects. Also returns the list of foreign
    nodes in this database, for which the calling peer is
    authoritative, to assist in synchronization of slivers.
    
    See the implementation of RefreshPeer for how this data is used.
    """

    roles = ['admin', 'peer']

    accepts = [Auth()]

    returns = {
        'Sites': Parameter([dict], "List of local sites"),
        'Keys': Parameter([dict], "List of local keys"),
        'Nodes': Parameter([dict], "List of local nodes"),
        'Persons': Parameter([dict], "List of local users"),
        'Slices': Parameter([dict], "List of local slices"),
        'db_time': Parameter(float, "(Debug) Database fetch time"),
        }

    def call (self, auth):
        start = time.time()

        # Filter out various secrets
        node_fields = filter(lambda field: field not in \
                             ['boot_nonce', 'key', 'session', 'root_person_ids'],
                             Node.fields)

	# added by nanodayo
	# Filter out local only node
	nodetags = NodeTags(self.api, {'tagname':'is_local','value':'True'},['node_id'])
	ignore_nodes = []
	for tags in nodetags:
		ignore_nodes.append(tags['node_id'])

	if ignore_nodes == []:
	        nodes = Nodes(self.api, {'peer_id': None}, node_fields);
	else :
	        nodes = Nodes(self.api, {'peer_id': None,'~node_id':ignore_nodes}, node_fields);

        # filter out whitelisted nodes
        nodes = [ n for n in nodes if not n['slice_ids_whitelist']] 
        

        person_fields = filter(lambda field: field not in \
                               ['password', 'verification_key', 'verification_expires'],
                               Person.fields)

        # XXX Optimize to return only those Persons, Keys, and Slices
        # necessary for slice creation on the calling peer's nodes.

	# filter out special person
	persons = Persons(self.api, {'~email':[self.api.config.PLC_API_MAINTENANCE_USER,
					       self.api.config.PLC_ROOT_USER],
				     'peer_id': None}, person_fields)

	# filter out system slices
        system_slice_ids = SliceTags(self.api, {'name': 'system', 'value': '1'}).dict('slice_id')
	slices = Slices(self.api, {'peer_id': None,
				   '~slice_id':system_slice_ids.keys()})
	
        result = {
            'Sites': Sites(self.api, {'peer_id': None}),
            'Keys': Keys(self.api, {'peer_id': None}),
            'Nodes': nodes,
            'Persons': persons,
            'Slices': slices,
            }

        if isinstance(self.caller, Peer):
            result['PeerNodes'] = Nodes(self.api, {'peer_id': self.caller['peer_id']})

        result['db_time'] = time.time() - start

        return result
