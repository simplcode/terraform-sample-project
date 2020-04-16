#!/usr/bin/env bash
sudo addgroup developers

sudo adduser -ingroup developers --disabled-password --gecos '' jason
sudo mkdir /home/jason/.ssh
sudo touch /home/jason/.ssh/authorized_keys
sudo echo "ssh-rsa TESTAABBECCCCKelklkjlkalkjIII+RPgL+0Icu0g1jQobWCjUkB1gJWxKuZ/UWy3IFpd7oRI+Q99PfRiSQGDPmE7b+E9iSctWmJkhafMbjEPpYde2xRM9BOrgG1eE0Q4dDLDZkTZWATvPmLZov2rb2LZXqg28IQ4IavfhVURkxdJJuQiiwmg9oS5Y/r1EjreWiJPEW2omRjZp1k4YSQK+5s63x77VnuU47o004mkT/7Go5z6t/wx2X5gDkFqWOTRLGbkTuIQXzwKEAXUc0NkJrhijxZhrdNTRy9Z9==
" | sudo tee /home/jason/.ssh/authorized_keys > /dev/null
sudo chown -R jason:developers /home/jason/.ssh
sudo chmod 700 /home/jason/.ssh; sudo chmod 600 /home/jason/.ssh/authorized_keys

sudo adduser -ingroup developers --disabled-password --gecos '' haein
sudo mkdir /home/haein/.ssh
sudo touch /home/haein/.ssh/authorized_keys
sudo echo "ssh-rsa TESTAABBECCCCKelklkjlkalkjIII+RPgL+0Icu0g1jQobWCjUkB1gJWxKuZ/UWy3IFpd7oRI+Q99PfRiSQGDPmE7b+E9iSctWmJkhafMbjEPpYde2xRM9BOrgG1eE0Q4dDLDZkTZWATvPmLZov2rb2LZXqg28IQ4IavfhVURkxdJJuQiiwmg9oS5Y/r1EjreWiJPEW2omRjZp1k4YSQK+5s63x77VnuU47o004mkT/7Go5z6t/wx2X5gDkFqWOTRLGbkTuIQXzwKEAXUc0NkJrhijxZhrdNTRy9Z9==
" | sudo tee /home/haein/.ssh/authorized_keys > /dev/null
sudo chown -R haein:developers /home/haein/.ssh
sudo chmod 700 /home/haein/.ssh; sudo chmod 600 /home/haein/.ssh/authorized_keys

sudo echo "%developers ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers > /dev/null

exit