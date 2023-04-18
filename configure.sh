#!/bin/bash

sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install ansible -y