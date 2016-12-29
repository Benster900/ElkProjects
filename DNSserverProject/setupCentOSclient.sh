#!/bin/bash

yum update -y && yum upgrade -y

############################### Install/Setup bind9 ###############################
yum install bind bind-utils -y
