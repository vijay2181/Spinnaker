################################################ RESTART SPINNAKER ###############################################################

sudo systemctl restart apache2
sudo systemctl restart gate
sudo systemctl restart orca
sudo systemctl restart igor
sudo systemctl restart front50
sudo systemctl restart echo
sudo systemctl restart clouddriver
sudo systemctl restart rosco

sleep 20
echo ""
echo "Spinnaker Installed Successfully...Open Browser And Access The Spinnaker with 'http://${MY_IP}:9000' url"
echo ""
