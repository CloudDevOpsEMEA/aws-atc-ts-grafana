#!/bin/bash

siege -c20 ${bigip_address} -b -t30s
