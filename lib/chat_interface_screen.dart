import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatInterfaceScreen extends StatefulWidget {
  final String chatId;
  final bool isGroup;

  const ChatInterfaceScreen({Key? key, required this.chatId, this.isGroup = false})
      : super(key: key);

  @override
  State<ChatInterfaceScreen> createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen> {
  final TextEditingController _messageController = TextEditingController();
  String currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  Future<void> initializeFields() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserEmail = prefs.getString('currentUserEmail') ?? '';
    });
  }

  Future<void> sendMessage() async {
    if (currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Could not retrieve user email.")),
      );
      return;
    }

    await sendMessageToDatabase(widget.chatId, _messageController.text, currentUserEmail);
    _messageController.clear();
  }

  Future<void> sendMessageToDatabase(String chatId, String content, String sender) async {
    await FirebaseFirestore.instance
        .collection(widget.isGroup ? 'groups' : 'chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'content': content,
      'sender': sender,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection(widget.isGroup ? 'groups' : 'chats').doc(chatId).update({
      'lastMessage': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _addMembersToGroup() {
    TextEditingController memberController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: memberController,
          decoration: const InputDecoration(hintText: 'Enter member\'s email'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (memberController.text.isNotEmpty) {
                String memberEmail = memberController.text.trim();

                try {
                  var userSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail)
                      .get();

                  if (userSnapshot.docs.isEmpty) {
                    throw Exception('User does not exist.');
                  }

                  await FirebaseFirestore.instance.collection('groups').doc(widget.chatId).update({
                    'users': FieldValue.arrayUnion([memberEmail]),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member added successfully!')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? 'Group Chat' : 'Chat'),
        actions: [
          widget.isGroup
              ? IconButton(onPressed: _addMembersToGroup, icon: const Icon(Icons.add))
              : const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.isGroup ? 'groups' : 'chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;
                Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};
                for (var message in messages) {
                  // Safely check if the 'timestamp' exists and is not null
                  final timestamp = message['timestamp'];
                  if (timestamp != null) {
                    final timestampDate = (timestamp is Timestamp)
                        ? timestamp.toDate()
                        : DateTime.now(); // Fallback to current date if timestamp is invalid or missing
                    final formattedDate = formatDate(timestampDate);

                    if (!groupedMessages.containsKey(formattedDate)) {
                      groupedMessages[formattedDate] = [];
                    }
                    groupedMessages[formattedDate]!.add(message);
                  }
                }

                return ListView.builder(
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, index) {
                    String date = groupedMessages.keys.toList()[index];
                    List<QueryDocumentSnapshot> dateMessages = groupedMessages[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              date,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).primaryColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        ...dateMessages.map((message) {
                          final isCurrentUser = message['sender'] == currentUserEmail;
                          final timestamp = message['timestamp'];
                          final timestampDate = (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();
                          final formattedTime = DateFormat('hh:mm a').format(timestampDate);

                          return Align(
                            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Theme.of(context).primaryColor : Theme.of(context).secondaryHeaderColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(message['content'], style: isCurrentUser ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54) : Theme.of(context).textTheme.bodyMedium),
                                  SizedBox(height: 5),
                                  Text(formattedTime, style: isCurrentUser ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54) : Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width < 600 ? 10 : 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
