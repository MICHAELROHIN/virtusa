import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';



import 'main.dart';class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  void sendMessage(String message) async {
    setState(() {
      messages.add({"sender": "user", "text": message});
      _isLoading = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/chat'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(Duration(seconds: 1)); // simulate typing delay
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
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildQuickReplies(List<String> suggestions) {
    return Wrap(
      spacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () {
            sendMessage(suggestion);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChatBubble(Map<String, String> message) {
    bool isUser = message["sender"] == "user";
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color userBg = Colors.blue.withOpacity(0.8);
    Color userText = Colors.white;

    // ⬇️ Faded black for dark mode, clean white for light mode
    Color botBg = isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9);
    Color botText = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment:
      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isUser ? userBg : botBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: isUser ? Radius.circular(12) : Radius.circular(0),
                bottomRight: isUser ? Radius.circular(0) : Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? "You" : "ZenBot",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser ? userText : botText,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  message["text"]!,
                  style: TextStyle(
                    color: isUser ? userText : botText,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isUser && message["text"]!.contains("suggestion:"))
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 4),
            child: _buildQuickReplies([
              "Tell me a joke",
              "Give me a quote",
              "Help with commands"
            ]),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/logo.png'),
                radius: 28,
                backgroundColor: Colors.transparent,
              ),
              SizedBox(width: 15),
              Text(
                "ZenBot",
                style: TextStyle(
                  fontFamily: 'Cormorant',
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              setState(() {
                messages.clear();
              });
            },
          ),
          Switch(
            value: Provider.of<ThemeProvider>(context).isDarkMode,
            onChanged: (value) {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
            },
            activeColor: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/bot.jpg",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text("ZenBot is typing..."),
                              ],
                            ),
                          ),
                        );
                      }
                      final message = messages[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 500),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildChatBubble(message),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.black),
                        onPressed: () {
                          // File upload logic
                        },
                      ),
                      SizedBox(width: 8),
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
                        icon: Icon(Icons.send, color: Colors.black),
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
        ],
      ),
    );
  }
}
