#!/bin/bash
set -x
cd /opt/chaperone-development
repo init -q -u https://github.com/vmware/chaperone -b master -g chaperone
repo sync

cd /opt/chaperone-development/ansible/playbooks/ansible
ansible-playbook -vvvv -i inventory ansible.yml

cd /opt/chaperone-development/ansible/playbooks/chaperone-ui
sed -i 's/base/local/g' base.yml
ansible-playbook -vvvv -i examples/inventory base.yml
sed -i 's/chaperone-ui/local/g' ui.yml
ansible-playbook -vvvv -i examples/inventory ui.yml --tags rsync