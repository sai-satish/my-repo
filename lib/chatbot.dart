import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:trip_swift/chat_with_AI.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const ChatBotScreen(),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final Map<String, dynamic> jsonObject = {};
  bool isLoading = false;
  bool isChatBotActive = false;

  int currentQuestionIndex = 0;

  final List<Map<String, dynamic>> questions = [
    {
      'type': 'text',
      'question': 'Where do you want to go?',
    },
    {
      'type': 'slider',
      'question': 'What is your budget level?',
      'options': ['Budget', 'Moderate', 'Luxury'],
    },
    {
      'type': 'date',
      'question': 'Select your start date.',
    },
    {
      'type': 'date',
      'question': 'Select your end date.',
    },
    {
      'type': 'multiple_choice',
      'question': 'What are your preferences?',
      'options': [
        'Culture',
        'Nature',
        'Adventure',
        'Relaxation',
        'Food',
        'Shopping',
        'Entertainment',
      ],
    },
  ];

  double _selectedBudgetIndex = 1; // Default to "Moderate"
  List<String> _selectedPreferences = []; // For multiple-choice selection

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      messages.add({'isUser': true, 'content': message});
      _inputController.clear();

      if (!isChatBotActive) {
        final question = questions[currentQuestionIndex];
        jsonObject[question['question']] = message;
        currentQuestionIndex++;
        if (currentQuestionIndex < questions.length) {
          _askNextQuestion();
        } else {
          _postUserDataToBackend();
        }
      } else {
        _sendToChatBot(message);
      }
    });
  }

  void _askNextQuestion() {
    final question = questions[currentQuestionIndex];
    messages.add({'isUser': false, 'content': question['question']});
    setState(() {});
  }

  Future<void> _postUserDataToBackend() async {
    const endpoint = "http://localhost:8000/generate-plan"; // Update with your endpoint
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode(jsonObject),
      );

      if (response.statusCode == 200) {
        messages.add({
          'isUser': false,
          'content': "Your travel plan is being generated! Let's chat about it."
        });
        isChatBotActive = true;
      } else {
        messages.add({'isUser': false, 'content': 'Failed to generate plan.'});
      }
    } catch (e) {
      messages.add({'isUser': false, 'content': 'Error: Could not connect to server.'});
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendToChatBot(String message) async {
    const endpoint = "http://localhost:8000/chatbot"; // Replace with your chatbot endpoint
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          messages.add({'isUser': false, 'content': responseData['reply']});
        });
      } else {
        messages.add({'isUser': false, 'content': 'Failed to communicate with chatbot.'});
      }
    } catch (e) {
      messages.add({'isUser': false, 'content': 'Error: Could not connect to chatbot.'});
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _askNextQuestion();
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
            _buildQuestionInput(),
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

  Widget _buildQuestionInput() {
    if (isChatBotActive) {
      return _buildTextInput();
    }

    final question = questions[currentQuestionIndex];
    if (question['type'] == 'text') {
      return _buildTextInput();
    } else if (question['type'] == 'slider') {
      return _buildSliderInput(question['options']);
    } else if (question['type'] == 'multiple_choice') {
      return _buildMultipleChoiceInput(question['options']);
    } else if (question['type'] == 'date') {
      return _buildDatePicker();
    }
    return const SizedBox.shrink();
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
                hintText: 'Your answer...',
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

// Remaining widgets (_buildSliderInput, _buildMultipleChoiceInput, _buildDatePicker) are the same


// Remaining widgets (_buildSliderInput, _buildMultipleChoiceInput, _buildDatePicker) are the same.



Widget _buildSliderInput(List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Slider(
            value: _selectedBudgetIndex,
            min: 0,
            max: options.length - 1.toDouble(),
            divisions: options.length - 1,
            label: options[_selectedBudgetIndex.toInt()],
            onChanged: (value) {
              setState(() {
                _selectedBudgetIndex = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              _sendMessage(options[_selectedBudgetIndex.toInt()]);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
  Map<String, dynamic> formattedJson(Map<String, dynamic> jsonObject) {
    return {
      'destination': jsonObject['Where do you want to go?'] ?? '',
      'start_date': jsonObject['Select your start date.'],
      'end_date': jsonObject['Select your end date.'],
      'budget': jsonObject['What is your budget level?'] ?? '',
      'travel_styles': jsonObject['answer'] != null ? _formatPreferences(jsonObject['answer']) : [],
    };
  }

  // String _formatDate(String date) {
  //   // You can replace this with your date formatting logic if needed
  //   // For example, converting "Dec 29, 2024" to "2024-12-29"
  //   DateTime parsedDate = DateTime.parse(date.split(',').reversed.join('-'));
  //   return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
  // }

  List<String> _formatPreferences(List<dynamic> preferences) {
    // If needed, you can modify the preferences (e.g., change case)
    return preferences.map((pref) => pref.toString().toLowerCase()).toList();
  }


  Widget _buildMultipleChoiceInput(List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: options.map((option) {
              final isSelected = _selectedPreferences.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPreferences.add(option);
                    } else {
                      _selectedPreferences.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedPreferences.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one preference')),
                );
                return;
              }

              // Add preferences to userAnswers in JSON-compatible format
              setState(() {
                jsonObject.addAll({
                  'question': questions[currentQuestionIndex]['question'],
                  'answer': _selectedPreferences, // Store as an array of strings
                });
                // print(jsonObject);
                var userInputs = formattedJson(jsonObject);
                _selectedPreferences.clear();
                print(userInputs);
                // _askNextQuestion();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context)=>ChatWithAI(userInputs)),
                );
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (selectedDate != null) {
            final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
            _sendMessage(formattedDate);
          }
        },
        child: const Text('Select Date'),
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
