# k8s-webterm-connector

> Tired with web terminals?
> Let's use it with CLI!

This is just a simple demo to bind a TCP port with k8s exec websocket API.
You can tweak it to suit your needs.

## Usage

```
cargo run <tcp-address-to-bind> <websocket-url>
```
You can also use the released binary instead of `cargo run`.

For example, bind `localhost:27730` with `wss://example.com/k8s-pod/exec?token=TOKEN`:
```
cargo run localhost:27730 'wss://example.com/k8s-pod/exec?token=TOKEN'
```

Keep it running, and then you can test it with:
```
socat - tcp:localhost:27730
```

## `tools/k8s-webterm-ssh-forward.sh`

As long as an IO method exists, you can use it for SSH conneciton.
```
tools/k8s-webterm-ssh-forward.sh <k8s-webterm-connector-bind-port> <pod-ssh-port> <forward-ssh-bind-port>
```

`socat` and `openssh-server` should be installed in the image of the target containers.

For example, k8s-webterm-connector binds `27730`.
The container can run an SSH server on `10022`.
And you would like to use SSH locally to connect the container on `27731`.
```
tools/k8s-webterm-ssh-forward.sh 27730 10022 27731
```

Keep it running, and then you can `ssh` to the container:
```
ssh -p 27731 USERNAME-IN-CONTAINER@localhost
```
