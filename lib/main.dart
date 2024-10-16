import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebSocketDemo(),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  late WebSocketChannel channel;
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController targetUserIdController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  String userId = '';
  String message = '';
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
  }

  void connectWebSocket() {
    if (userId.isNotEmpty) {
      channel = IOWebSocketChannel.connect(
          'wss://websocket-rnd-b5c2df490d3b.herokuapp.com?userId=$userId');

      channel.stream.listen((data) {
        setState(() {
          message = 'Message: $data';
        });

        // Optionally handle pong responses here
      }, onDone: () {
        print('Connection closed. Attempting to reconnect...');
        _startReconnection();
      }, onError: (error) {
        print('Error: $error');
        _startReconnection();
      });

      // Start sending keep-alive pings
     // _startKeepAlive();
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (channel != null) {
        // Send a ping message
        channel.sink.add('ping'); // Use a meaningful ping message if needed
      }
    });
  }

  void _startReconnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      print('Attempting to reconnect...');
      connectWebSocket(); // Try to reconnect every 5 seconds
      if (channel != null) {
        _reconnectTimer?.cancel(); // Stop reconnection attempts if successful
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: userIdController,
              decoration: InputDecoration(
                labelText: 'Enter your User ID',
              ),
              onSubmitted: (text) {
                setState(() {
                  userId = text;
                });
                connectWebSocket(); // Connect after entering the user ID
              },
            ),
            TextField(
              controller: targetUserIdController,
              decoration: InputDecoration(
                labelText: 'Enter Target User ID',
              ),
            ),
            TextField(
              controller: messageController,
              onSubmitted: (text) {
                if (channel != null && targetUserIdController.text.isNotEmpty) {
                  // Construct message with target user ID
                  final payload = {
                    'targetUserId': targetUserIdController.text,
                    'message': text,
                  };
                  channel.sink.add(payload.toString()); // Send message to WebSocket server
                  messageController.clear(); // Clear the input field after sending
                }
              },
              decoration: InputDecoration(
                labelText: 'Send a message',
              ),
            ),
            SizedBox(height: 20),
            Text(message), // Display incoming messages
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    userIdController.dispose();
    targetUserIdController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
