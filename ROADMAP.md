## MVP

* implement consistent config handling
* Run applications as users, not root, inside containers
* clean up old application images/containers
* 2 or 3 more servicepacks, mongo, <strike>redis</strike>, rabbitmq, etc.
* documentation for both pocketpaas and servicepack
  * reference
  * quick start
* packaging for both
* <strike>push routing config into hipache</strike>
* <strike>hipache container set up</strike>
* <strike>app config yaml file</strike>
* <strike>stop application</strike>
* <strike>start application</strike>
* <strike>delete application</strike>
* <strike>service provisioning with servicepack</strike>

## Future

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
