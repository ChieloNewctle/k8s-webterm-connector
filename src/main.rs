use std::time::Duration;

use futures_util::{SinkExt, StreamExt};
use tokio::io::AsyncWriteExt;
use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::tungstenite::handshake::client::generate_key;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::{connect_async, tungstenite};
use tokio_util::codec::{BytesCodec, FramedRead};

async fn handle_conn(target_url: String, target_host: String, mut socket: TcpStream) {
    let (socket_reader, mut socket_writer) = socket.split();
    let mut framed_reader = FramedRead::new(socket_reader, BytesCodec::new());

    let ws_conn_request = tungstenite::handshake::client::Request::get(target_url)
        .header("Host", &target_host)
        .header("Sec-WebSocket-Protocol", "channel.k8s.io")
        .header("Connection", "Upgrade")
        .header("Upgrade", "websocket")
        .header("Sec-WebSocket-Version", "13")
        .header("Sec-WebSocket-Key", generate_key())
        .body(())
        .expect("failed to create request");

    let (ws_client, _ws_conn_response) = connect_async(ws_conn_request)
        .await
        .expect("failed to create connection");

    // eprintln!("websocet connect response: {:?}", _ws_conn_response);

    let (mut ws_sink, mut ws_stream) = ws_client.split();

    let mut keepalive_timer = tokio::time::interval(Duration::from_secs(10));

    loop {
        tokio::select! {
            _keepalive = keepalive_timer.tick() => {
                // eprintln!("keepalive: {:?}", _keepalive);
                ws_sink.send(
                    Message::Binary(vec![0u8]))
                    .await
                    .expect("failed to send to websocket sink");
            }
            msg_res = ws_stream.next() => {
                match msg_res {
                    Some(Ok(msg)) => match msg {
                        Message::Binary(data) => {
                            match data[0] {
                                1 => {
                                    socket_writer.write_all(&data[1..])
                                        .await
                                        .expect("failed to write to tcp sink");
                                }
                                2 => {
                                    eprintln!("web terminal stderr: {:?}", data);
                                }
                                _ => {
                                    // eprintln!("unknow binary data from websocket: {:?}", data);
                                }
                            }
                        }
                        Message::Ping(data) => {
                            ws_sink.send(Message::Pong(data))
                                .await
                                .expect("failed to send to websocket sink");
                        }
                        Message::Close(close) => {
                            eprintln!("websocket closed: {:?}", close);
                            return;
                        }
                        _msg => {
                            // eprintln!("websocket got unhandled message: {:?}", _msg);
                        },
                    },
                    Some(Err(err)) => {
                        eprintln!("got error from websocket stream: {:?}", err);
                        return;
                    }
                    None => {
                        eprintln!("websocket stream breakdown");
                        return;
                    }
                }
            }
            bytes_res = framed_reader.next() => {
                match bytes_res {
                    Some(Ok(bytes)) => {
                        ws_sink.send(
                            Message::Binary(
                                (vec![0u8])
                                    .into_iter()
                                    .chain(bytes.into_iter())
                                    .collect()
                            )
                        ).await.expect("failed to send to websocket sink");
                    }
                    Some(Err(err)) => {
                        eprintln!("got error from tcp stream: {:?}", err);
                        return;
                    }
                    None => {
                        eprintln!("tcp stream breakdown");
                        ws_sink.send(Message::Close(None))
                            .await
                            .expect("failed to send to websocet sink");
                        return;
                    }
                }
            }
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let bind_addr = std::env::args().nth(1).expect("no bind address given");

    let target_url = std::env::args().nth(2).expect("no bind address given");
    let parsed_url = url::Url::parse(&target_url).expect("wrong format of url");
    let target_host = parsed_url.host_str().expect("no hostname found in url");

    let listener = TcpListener::bind(&bind_addr).await?;

    eprintln!("listening to {}...", bind_addr);

    loop {
        let (socket, remote_addr) = listener.accept().await?;
        eprintln!("remote address: {:?}", remote_addr);
        tokio::spawn(handle_conn(
            target_url.to_owned(),
            target_host.to_owned(),
            socket,
        ));
    }
}
