## MVP

* clean up old application images/containers
* documentation for both pocketpaas and servicepack
  * reference
  * quick start
* servicepack
  * <strike>move ssh key from build to setup</strike>
  * add version
  * <strike>remove backup and extra as we don't need them yet</strike>
* <strike>implement consistent config handling</strike>
* <strike>push routing config into hipache</strike>
* <strike>hipache container set up</strike>
* <strike>app config yaml file</strike>
* <strike>stop application</strike>
* <strike>start application</strike>
* <strike>delete application</strike>
* <strike>service provisioning with servicepack</strike>

## Future

* packaging for both
* allow specifying ssl cert for https hipache, and autogenerate one if none provided
* 2 or 3 more servicepacks, <strike>mongo</strike>, <strike>redis</strike>, rabbitmq, etc.
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
