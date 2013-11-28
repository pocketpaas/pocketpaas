## MVP

* clean up old application images/containers
* add build or pull configuration
* set up buildstep as part of setup
* add dev setup instructions (vagrant box, etc.)
* documentation for pocketpaas
  * reference
  * quick start
* DONE: documentation for servicepack
  * DONE: reference
  * DONE: quick start
* DONE: servicepack
  * DONE: move ssh key from build to setup
  * DONE: add version
  * DONE: remove backup and extra as we don't need them yet
* DONE: implement consistent config handling
* DONE: push routing config into hipache
* DONE: hipache container set up
* DONE: app config yaml file
* DONE: stop application
* DONE: start application
* DONE: delete application
* DONE: service provisioning with servicepack

## Future

* packaging for both
* allow specifying ssl cert for https hipache, and autogenerate one if none provided
* 2 or 3 more servicepacks, rabbitmq, etcd, etc.
* Run applications as users, not root, inside containers
* Run sshd in application containers to allow logging in
* Figure out a convention for handling logs
* swap application (start up another build and swap out of hipache)
* clean up output
* aliasing
* staging
* running non-buildpack containers
* running non-servicepack services
* adding arbitrary environment variables to applications
* many more yaml file features
* iptables (in service containers) to limit connections between containers and services
