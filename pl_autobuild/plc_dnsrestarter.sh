#!/bin/bash

chroot /plc/root/ /etc/plc.d/dns stop
chroot /plc/root/ /etc/plc.d/dns start
