#!/bin/bash

sudo apt install tinyproxy
#Intermediate step if proxy does not work properly. Check the configuration file '/etc/tinyproxy/rinyproxy.conf' for the port. Should be 8888
#URL: https://cloud.google.com/kubernetes-engine/docs/tutorials/private-cluster-bastion

sudo sed  -i "/Allow 127/a\\Allow localhost"  /etc/tinyproxy/tinyproxy.conf

sudo service tinyproxy restart

