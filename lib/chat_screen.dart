import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  void sendMessage(String message) async {
    setState(() {
      messages.add({"sender": "user", "text": message});
      _isLoading = true; // Show loading indicator
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/chat'), // Ensure backend is running
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({"sender": "bot", "text": data["response"]});
        });
      } else {
        setState(() {
          messages.add({"sender": "bot", "text": "Error: Unable to get response!"});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "bot", "text": "Error: Failed to connect to the server!"});
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ZenBot")),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bot.jpg"), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: messages[index]["sender"] == "user"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: messages[index]["sender"] == "user"
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messages[index]["sender"] == "user" ? "You" : "Bot",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: messages[index]["sender"] == "user"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            messages[index]["text"]!,
                            style: TextStyle(
                              color: messages[index]["sender"] == "user"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading) CircularProgressIndicator(), // Show loading indicator
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: "Enter message",
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
