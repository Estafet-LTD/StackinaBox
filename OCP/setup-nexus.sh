# Install Nexus

wget repo.thales.com/nexus/nexus.tar.gz
mkdir /opt/nexus
tar xzf nexus.tar.gz --directory=/opt/nexus

# create a user
useradd --system -M --comment 'Nexus user' nexus

chown nexus:nexus /opt/nexus -R


# Add service
cp -fv /home/engineer/ocp/nexus.service /etc/systemd/system/nexus.service

# Start and enable the service now
systemctl daemon-reload
systemctl enable nexus.service
systemctl start nexus.service
