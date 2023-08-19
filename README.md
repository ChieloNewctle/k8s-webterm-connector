# k8s-webterm-connector

> Tired with web terminals?
> Let's use it with CLI!

This is just a simple demo to bind a TCP port with k8s exec websocket API,
which use `channel.k8s.io` as subprotocol.

You can tweak it to suit your needs.

## Usage

```sh
cargo run <tcp-address-to-bind> [websocket-url|file-url]
```

**You can also use [the latest release](https://github.com/ChieloNewctle/k8s-webterm-connector/releases/latest) instead of `cargo run`.**

### WebSocket URL Example

For example, bind `localhost:27730` with `wss://example.com/k8s-pod/exec?token=TOKEN`:

```sh
cargo run localhost:27730 'wss://example.com/k8s-pod/exec?token=TOKEN'
```

Keep it running, and then you can test it with:

```sh
socat - tcp:localhost:27730
```

### File URL Example

For example, a file in `/tmp/k8s-webterm-connector-ws-27730-url.txt` contains the websocket URL:

```url
wss://example.com/k8s-pod/exec?token=TOKEN
```

Then you can bind `localhost:27730` to the webterm URL in that file with:

```sh
cargo run localhost:27730 file:///tmp/k8s-webterm-connector-ws-27730-url.txt
```

Keep it running, and then you can test it with:

```sh
socat - tcp:localhost:27730
```

## SSH via k8s-webterm-connector

> As long as an IO method exists, you can use it for SSH conneciton.

`socat` and `openssh-server` should be installed in the image of the target containers.

You can use `tools/proxy-ssh-via-k8s-webterm.sh`
as `ProxyCommand` in your `~/.ssh/config`.

```ssh-config
Host <hostname-you-like>
  ProxyCommand <...>/k8s-webterm-connector/tools/proxy-ssh-via-k8s-webterm.sh <connector-bind-port> <port-inside-container>
  HostName <any-valid-hostname>
  User <username-in-container>
  ServerAliveInterval 15
  StrictHostKeyChecking no
```

### Example

For example, k8s-webterm-connector is **running** and binds `27730`.
Inside the target container, `10022` TCP port is available or used for SSH.

```ssh-config
Host k8s-container
  ProxyCommand ~/k8s-webterm-connector/tools/proxy-ssh-via-k8s-webterm.sh 27730 10022
  HostName container
  User root
  ServerAliveInterval 15
  StrictHostKeyChecking no
```

Then you can ssh into the container:

```sh
ssh k8s-container
```

## Multiplex SSH via k8s-webterm-connector and port forwarding

This tool wraps `tools/proxy-ssh-via-k8s-webterm.sh` and forward SSH port to the local machine.

It will be _more stable_ if URL to the webterm is constantly changing,
but _less efficient_ as only one connection is created.

```sh
./tools/k8s-webterm-ssh-forward.sh <k8s-webterm-connector-bind-port> <pod-ssh-port> <forward-ssh-bind-port>
```

`socat` and `openssh-server` should be installed in the image of the target containers.

### Example

For example, k8s-webterm-connector is **running** and binds `27730`.
Inside the target container, `10022` TCP port is available or used for SSH.
And you would like to use SSH locally to connect the container on `27731`.

```sh
./tools/k8s-webterm-ssh-forward.sh 27730 10022 27731
```

Keep it running, and then you can `ssh` to the container:

```sh
ssh -p 27731 USERNAME-IN-CONTAINER@localhost
```
