# Warning

This project isn't quite ready for mass consumption.  There will be a quickstart guide soon to help with setup.

Do feel free to look around in the meantime, if you'd like.

# Overview

PocketPaaS - the PaaS that's so small, it could fit in your pocket.

PocketPaaS is designed for single server deployments.  It can't autoscale your
application or bring up a HA load balancer.  You can't administrate it from far
away lands and it won't provide you with fancy dashboards.  It's designed to
handle the applications on one server and handle them well, so you don't have
to.

# Why?

I've used various PaaS platforms (dotCloud and Stackato) for years and I've always wanted a simple setup for running my applications.

My requirements:

* Free - For the applications I run personally, I don't have the budget for license fees.
* Simple - I'd like to run applications with nothing more than a bit of source code and a name.
* Support for services - If I want to have a database for my application, I want to be able to specify that with my application and have the application find out about it with environment variables.  See [The Twelve-Factor App](http://12factor.net/).
* Lightweight - I'd rather not have an API, message queue, database instance and twelve other processes running just so that I can keep watch over my applications.

# Quickstart

TBD

# YAML config file

Currently there are only a few top level keys allowed in the YAML file.

## `name` - The name of the application

This is a simple name that will be used to refer to the application in
PocketPaaS.

This can also be specified with the `--name` command line argument.

Example:

```
name: foobar
```

## `services` - The services that the application requires

The value is an array of hashes.  The key of each hash is the name of the
service and the value is the type of service.  Simple names can be used to
indicate the following services, or a full git url can be specified that points
to something servicepack can understand:

* **mysql** - MySQL 5.5
* **redis** - Redis 2.6

This can also be specified with multiple `--service name:type` command line
arguments to `pps push`.

Example:

```
services:
 - mydb: mysql
```

# Thanks

This project stands on the shoulders of many giants.  It would not be possible without the following projects:

* [Docker](http://docker.io)
* [Buildstep](https://github.com/progrium/buildstep) and [Heroku](https://www.heroku.com/) for [buildpacks](https://devcenter.heroku.com/articles/buildpacks)
* [Perl](http://perl.org)
* [Carton](https://metacpan.org/module/Carton) and many other CPAN modules.

And many others.  Thank you for contributing your work so that I could contribute mine.

The logo on github is from [Erin Standley](http://thenounproject.com/noun/pocket/#icon-No17671), from the excellent [Noun Project](http://thenounproject.com/).

# License

Copyright 2013 Nate Jones
Licensed under the Apache License, Version 2.0.

## Software licenses

* Docker licensed under the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0)
* Buildstep licensed under the [MIT License](http://opensource.org/licenses/MIT)
* All Perl modules listed in [cpanfile](cpanfile) licensed under the [Artistic License 2.0](http://opensource.org/licenses/Artistic-2.0), except:
  * Perl::Tidy licensed under the [GPL](http://opensource.org/licenses/gpl-license)
