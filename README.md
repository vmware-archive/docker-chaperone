# docker-chaperone

Builds docker images for running the various Chaperone containers. There are
two types of containers: developer and deployment. The former includes a number
of tools like ssh (for logging to the container), repo, git, vim (editor),
ansible and that which is necessary to develop for Chaperone.

The latter is just a basic container: openedge/chaperone-base. That is just
enough services (ssh and a basic setup) for configuring form a developer
container with Ansible as per normal working modes.

# Requirements

A working Docker setup and a valid shell (e.g., bash).

## Getting Started
Build the containers and run them. Thereafter, configure the containers as
desired.

For example, adding ~/.ssh/config files, enabling geany-plugins, etc. If
already pushed to docker hub, just 'docker run' appropriately (no need to
build).

```
./build.sh
docker login
docker push openedge/chaperone-base
docker push openedge/chaperone-dev
docker push openedge/chaperone-lxde
```

To run a developer setup with no X11 support, placing code sources in
your host machine's ~/chaperone directory, allowing SSH logins on host
port 2222.

```
docker run -d -v ~/chaperone:/home/vmware/chaperone -p 2222:22 openedge/chaperone-dev
```

To run a developer setup with the same as above but with X11 support,
Geany and all Geany plugins as an editor:

```
docker run -d -v ~/chaperone:/home/vmware/chaperone -p 2222:22 -p 5900:5900 openedge/chaperone-lxde
```

Once running you can either SSH to (on your host) localhost:2222 or use a vnc
viewer and connect to :0 (port 5900) as in:

```
vncviewer localhost:0
```

By default, the password is empty for vnc sessions.

To run a deployment server setup:

```
docker run -d -p 2223:22 -p 8080:80 openedge/chaperone-base
```

Note that when using that setup, you now have two choices in running the
Ansible playbooks against the deployment server (container). Either assure
That Ansible uses port 2223 for its SSH operations if you point your inventory
file at your host machine, or use port 22 if you point your inventory file(s)
toward the Docker network address (usually something of the form 172.17.0.???).
Finally, the container started as a result of the above would allow browser
connections on host port 8080.

# License and Author

Copyright: Copyright (c) 2015 VMware, Inc. All Rights Reserved

Author: Tom Hite

License: Apache License, Verison 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

