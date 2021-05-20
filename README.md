# Ansible Role: ansible-bluegreen-docker

[![Build Status](https://travis-ci.org/decayofmind/ansible-bluegreen-docker.svg?branch=master)](https://travis-ci.org/decayofmind/ansible-bluegreen-docker)

Simple Ansible role showing the concept of downtimeless deployments with Docker containers, but without orchestrator (Swarm, Kubernetes, etc.)

## Disclaimer

Yes, I know about Kubernetes/Nomad/Swarm and other better methods to deploy an application in Docker containers.
But there are cases, where the usage of orchestrator is bringing excessive complexity and is ""heavier" than an actual application workload.

If your infrastructure has one or two hosts and you need to deploy containerized web applications to them effectively,
this role might be helpful.


The original pattern of [blue-green deployments](http://martinfowler.com/bliki/BlueGreenDeployment.html) describes two copies
of entire infrastructure with a router, switching traffic from old copy to a new one after a successful deployment.

This pattern can not be applied in this role to the full extent. However, during the run, the role will create a set of new containers alongside
the old ones still running. The traffic will be switched to new containers (by modifying Nginx config) only after a successful healthcheck.
So as you can see, the approach is quite similar to the original blue-green idea.


The deployment itself is done by `docker_container` Ansible module.
Please refer to its [documentation](https://docs.ansible.com/ansible/latest/modules/docker_container_module.html) for more details.


## Role Variables

| Variable                               | Description                                                                                                                          | Default                                |
| ---                                    | ---                                                                                                                                  | ---                                    |
| `app_name`                             | Application name. Also used for container naming.                                                                                    | `trainingwheels`                       |
| `app_image`                            | Name of the Docker image to pull.                                                                                                    | `decayofmind/trainingwheels`           |
| `app_port`                             | Internal TCP port where app is listening for connections.                                                                            | `5000`                                 |
| `app_version`                          | Docker image tag.                                                                                                                    | `latest`                               |
| `app_instances_count`                  | Number of containers to be run.                                                                                                      | `2`                                    |
| `app_command`                          | Command to be executed in a container                                                                                                | `""`                                   |
| `app_etc_hosts`                        | Custom _hostname_ to _IP_ mappings for _/etc/hosts_ in container.                                                                    | `{}`                                   |
| `app_env`                              | Environment variables passed to a container's shell.                                                                                 | `{}`                                   |
| `app_volumes`                          | Volumes mounted into container.                                                                                                      | `[]`                                   |
| `app_log_driver`                       | Driver for capturing logs in containers.                                                                                             | `none`                                 |
| `app_log_options`                      | Options for log driver.                                                                                                              | `{}`                                   |
| `app_port_prefix`                      | Prefix for ports, opened for containers on host if `app_bluegreen_enabled` is disabled.                                              | `401`                                  |
| `app_bluegreen_enabled`                | Enables downtimeless deployment.                                                                                                     | `yes`                                  |
| `app_bluegreen_default_color`          | Tag for the first deployment (better to leave as is).                                                                                | `green`                                |
| `app_bluegreen_tags.blue`              | Hash with defaults for blue deployments (better to leave as is).                                                                     | `{"name":"blue", "port_prefix": 402}`  |
| `app_bluegreen_tags.green`             | Hash with defaults for green deployments (better to leave as is).                                                                    | `{"name":"green", "port_prefix": 407}` |
| `app_nginx_enabled`                    | Enables generation of Nginx config for balancing between containers.                                                                 | `yes`                                  |
| `app_nginx_hostnames`                  | Hostanames, which Nginx will accept.                                                                                                 | `["localhost"]`                        |
| `app_nginx_upstream_name`              | Upstream name for Nginx configuration (better to leave as is).                                                                       | `{{ app_name }}`                       |
| `app_nginx_port`                       | Port where Nginx is listening to incoming external requests.                                                                         | `80`                                   |
| `app_nginx_ip_hash`                    | Enable [ip-hash](http://nginx.org/en/docs/http/load_balancing.html#nginx_load_balancing_methods) load-balancing algorithm for nginx. | `no`                                   |
| `app_nginx_crossbalance_enabled`       | Application containers of other hosts will be added to Nginx upstream if enabled.                                                    | `yes`                                  |
| `app_nginx_crossbalance_hosts`         | List of hosts to add to Nginx upstream (better to leave as is).                                                                      | `{{ ansible_play_hosts }}`             |
| `app_nginx_conf_backup_retention`      | Count of Nginx configuration backup to keep                                                                                          | `3`                                    |
| `app_old_containers_treatment_enabled` | Enable to stop or remove containers left from the previous deployment.                                                               | `yes`                                  |
| `app_old_containers_treatment_type`    | What to do with containers of previous deployment (color). May be `absent` or `stopped`.                                             | `absent`                               |
| `app_healthcheck_enabled`              | Perform a healthcheck on newly deployed containers.                                                                                  | `yes`                                  |
| `app_healthcheck_path`                 | Healthcheck path.                                                                                                                    | `/`                                    |
| `app_cleanup_dead_containers`          | Enables deletion of any dead containers left.                                                                                        | `yes`                                  |


### Temporary Variables

Following variables will appear in runtime:

| Variable                  | Description                                                                       |
| ---                       | ---                                                                               |
| `_app_first_run`          | Is `True` if role is run for the first time (local facts are checked for it).     |
| `_app_prev_color`         | Tag of the previous deployment (fetched from local facts of `app_default_color`). |
| `_app_prev_count`         | Containers count of the previous deployment (fetched from local facts).           |
| `_app_prev_version`       | Previous version of the deployed application (fetched from local facts).          |
| `_app_next_color`         | Tag of the ongoing deployment. The opposite of `_app_prev_color`.                 |
| `_app_deployemnt`         | Returned values from `docker_container` module.                                   |
| `_app_ports`              | Exposed ports of newly deployed containers (taken from `_app_deployment`).        |
| `_app_dead_containers`    | Hashes of containers with dead status if found.                                   |
| `_app_healthcheck_result` | Result of ongoing healthchecks.                                                   |
| `_app_nginx_conf_test`    | Result of Nginx config check.                                                     |


## Requirements

* docker-engine (not in meta)
* nginx (not in meta)

Additionally for my test application (_decayofmind/trainingwheels_) you will need Redis.


## Nginx Balancing

1. Ansible gets a list of all published ports in containers.
2. Ansible prepares an Nginx config with all published container's ports of all(!) app hosts.


## Desired Architecture
![architecture diagram](docs/architecture.png)
