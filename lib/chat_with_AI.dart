import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme/theme.dart';

class ChatWithAI extends StatefulWidget {
  final Map<String, dynamic> userData;

  ChatWithAI(this.userData, {Key? key}) : super(key: key);
  @override
  State<ChatWithAI> createState() => _ChatWithAIState();
}

class _ChatWithAIState extends State<ChatWithAI> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Sending the user data to the endpoint immediately after the screen is loaded
    _sendToChatBot(widget.userData);
  }

  Future<void> _sendToChatBot(Map<String, dynamic> preferences) async {
    const endpoint = "http://localhost:8000/generate-plan"; // Replace with your chatbot endpoint
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode(preferences),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          messages.add({'isUser': false, 'content': responseData['travel_plan']});
        });
      } else {
        setState(() {
          messages.add({'isUser': false, 'content': 'Failed to communicate with chatbot.'});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'isUser': false, 'content': 'Error: Could not connect to chatbot.'});
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      messages.add({'isUser': true, 'content': message});
      _inputController.clear();
    });

    // Send a travel plan or preferences to the chatbot
    _sendToChatBot({
      "destination": "Paris", // Example, replace with dynamic values
      "present_location": "NYC",
      "start_date": "2024-01-01",
      "end_date": "2024-01-10",
      "budget": "medium",
      "travel_styles": ["adventure", "culture"]
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            _buildHeader(),
            if (isLoading) const LinearProgressIndicator(),
            Expanded(child: _buildChatArea()),
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF262730),
      child: const Text(
        '🌎 AI Travel Planner',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Align(
          alignment: message['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            color: message['isUser']
                ? const Color(0xFF6B6BFF)
                : const Color(0xFF262730),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message['content'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: child,
    );
  }
}
