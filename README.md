# k8s-webterm-connector

> Tired with web terminals?
> Let's use it with CLI!

This is just a simple demo to bind a TCP port with k8s exec websocket API.
You can tweak it to suit your needs.

## Usage

```
cargo run <tcp-address-to-bind> <websocket-url>
```

You can also use the latest release instead of `cargo run`.

For example, bind `localhost:27730` with `wss://example.com/k8s-pod/exec?token=TOKEN`:

```
cargo run localhost:27730 'wss://example.com/k8s-pod/exec?token=TOKEN'
```

Keep it running, and then you can test it with:

```
socat - tcp:localhost:27730
```

## SSH via k8s-webterm-connector

> As long as an IO method exists, you can use it for SSH conneciton.

`socat` and `openssh-server` should be installed in the image of the target containers.

You can use `tools/proxy-ssh-via-k8s-webterm.sh`
as `ProxyCommand` in your `~/.ssh/config`.

```
Host <hostname-you-like>
  ProxyCommand <...>/k8s-webterm-connector/tools/proxy-ssh-via-k8s-webterm.sh <connector-bind-port> <port-inside-container>
  HostName <any-valid-hostname>
  User <username-in-container>
  ServerAliveInterval 15
```

### Example

For example, k8s-webterm-connector is **running** and binds `27730`.
Inside the target container, `10022` TCP port is available or used for SSH.

```
Host k8s-container
  ProxyCommand ~/k8s-webterm-connector/tools/proxy-ssh-via-k8s-webterm.sh 27730 10022
  HostName container
  User root
  ServerAliveInterval 15
```

Then you can ssh into the container:

```
ssh k8s-container
```

## Forward SSH via k8s-webterm-connector

This tool wraps `tools/proxy-ssh-via-k8s-webterm.sh` and forward SSH port to the local machine.

```
./tools/k8s-webterm-ssh-forward.sh <k8s-webterm-connector-bind-port> <pod-ssh-port> <forward-ssh-bind-port>
```

`socat` and `openssh-server` should be installed in the image of the target containers.

### Example

For example, k8s-webterm-connector is **running** and binds `27730`.
Inside the target container, `10022` TCP port is available or used for SSH.
And you would like to use SSH locally to connect the container on `27731`.

```
./tools/k8s-webterm-ssh-forward.sh 27730 10022 27731
```

Keep it running, and then you can `ssh` to the container:

```
ssh -p 27731 USERNAME-IN-CONTAINER@localhost
```
