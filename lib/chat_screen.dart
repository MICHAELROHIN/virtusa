import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chat_messages') ?? [];
    setState(() {
      messages = savedMessages.map((msg) {
        final decoded = jsonDecode(msg);
        return {
          "sender": decoded['sender'].toString(),
          "text": decoded['text'].toString(),
        };
      }).toList();
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final msgList = messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList('chat_messages', msgList);
  }

  void sendMessage(String message) async {
    setState(() {
      messages.add({"sender": "user", "text": message});
      _isLoading = true;
    });
    await _saveMessages();
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
        _saveMessages();
      } else {
        setState(() {
          messages.add({"sender": "bot", "text": "Error: Unable to get response!"});
        });
        _saveMessages();
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "bot", "text": "Error: Failed to connect to the server!"});
      });
      _saveMessages();
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

    Color userBg = isDark ? Colors.blue.withOpacity(0.8) : Colors.blue.shade100;
    Color userText = isDark ? Colors.white : Colors.black;

    Color botBg = isDark ? Colors.black.withOpacity(0.7) : Colors.grey.shade200;
    Color botText = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: isUser ? userText : botText),
                ),
                SizedBox(height: 5),
                Text(message["text"]!, style: TextStyle(color: isUser ? userText : botText)),
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
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage("assets/logo.png"),
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
              _saveMessages();
            },
          ),
          SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton<String>(
              icon: FirebaseAuth.instance.currentUser?.photoURL != null
                  ? CircleAvatar(
                backgroundImage: NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!),
              )
                  : CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  FirebaseAuth.instance.currentUser?.email?[0].toUpperCase() ?? "?",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/');
                } else if (value == 'settings') {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings, color: Colors.black),
                                SizedBox(width: 10),
                                Text(
                                  'Settings',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Divider(thickness: 1, height: 20),
                            ListTile(
                              leading: Icon(Icons.brightness_6),
                              title: Text('Dark Mode'),
                              trailing: Consumer<ThemeProvider>(
                                builder: (context, themeProvider, _) => Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    themeProvider.toggleTheme(value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),

          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/bot.jpg", fit: BoxFit.cover),
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
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: "Enter message",
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.white.withOpacity(0.8),
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
