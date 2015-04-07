# Description

EYWA PoC, OpenNebula on Vagrant Environment

# Dashboard

![Dashboard](etc-files/Dashboard.png)

# Prepair OpenNebula Env.

## Post-Installation

### Build Master Node (Front-end)

```bash
host> vagrant up master
host> vagrant ssh master
master> sudo /home/vagrant/config-one-env.sh
```

#### config-one-env.sh

* Create Virtual-Network
* Create Image (CentOS 6.5 x86_64)
* Create Template (CentOS-6.5_64)

### Build Slave Node

```bash
host> vagrant up slave-1
```

### Using Desktop VNC

* Connecting /w VNC

```
VNC Address: {Host-IP}:5900
```

### (Note)

* You will need to wait until the image is READY to be used.
* Where is...., in "Virtual Resource" Tab -> "Images" Tab

## Login Web-UI
  * http://{Host-IP}:9869
  * Admin ID/PW: oneadmin / passw0rd

## Architecture of EYWA

![Architecture](etc-files/Architecture.png)

## (Note)

* VNC Console is not supported. Because of Port Forwarding (>5900, Random)
