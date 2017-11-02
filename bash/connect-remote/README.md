# Usage

```
connect-remote.sh <start|stop|status|list> <dir> [index]

start:  Starts a connection
stop:   Kills process associatd with connection
status: Lists active connections
list:   Lists entries in ${SERVERS}

<dir> is a directory which contains a 'servers.cfg' file
[index] is an index in the ${SERVERS} array, referenced by index id
```

### example

Initiates first connection listed in `${SERVERS}` array, as defined by `servers.cfg` in the `ssh-example-site` directory:

```
connect-remote.sh start ssh-example-site 0
```