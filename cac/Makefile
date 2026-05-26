.PHONY: all deps run ping check dry-run

all: deps run

deps:
	ansible-galaxy collection install -r collections/all.yml

run:
	ansible-playbook main.yml

ping: 
	ansible all -i inventory.ini -m ping

check:
	ansible-playbook main.yml --syntax-check

dry-run:
	ansible-playbook main.yml --check
