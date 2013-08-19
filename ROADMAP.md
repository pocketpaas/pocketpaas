## MVP

* implement consistent config handling
* Run applications as users, not root, inside containers
* <strike>config yaml file</strike>
* hipache container set up
* push routing config into hipache
* <strike>stop application</strike>
* <strike>start application</strike>
* <strike>delete application</strike>
* clean up old application images/containers
* <strike>service provisioning with servicepack</strike>
* 2 or 3 more servicepacks, mongo, <strike>redis</strike>, rabbitmq, etc.
* documentation for both pocketpaas and servicepack
  * reference
  * quick start
* packaging for both

## Future

* Run sshd in application containers to allow logging in
* Figure out a convention for handling logs
* swap application (start up another build and swap out of hipache)
* clean up output
* aliasing
* staging
* running non-buildpack containers
* adding arbitrary environment variables to applications
* many more yaml file features
* iptables (in service containers) to limit connections between containers and services
