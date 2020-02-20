# Install Nexus

wget repo.thales.com/nexus/nexus.tar.gz
tar xzf nexus.tar.gz --directory=/opt

# create a user
useradd --system --comment 'Nexus user' nexus



# Add service
cp -fv /home/engineer/ocp/nexus.service /etc/systemd/system/nexus.service

# Start and enable the service now
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus