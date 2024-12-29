import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TravelPlannerScreen extends StatefulWidget {
  const TravelPlannerScreen({super.key});

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  final TextEditingController _questionController = TextEditingController();
  String? destination;
  String? presentLocation;
  DateTime? startDate;
  DateTime? endDate;
  String budget = 'Moderate';
  List<String> travelStyles = [];
  String? travelPlan;
  bool isLoading = false;
  List<Map<String, dynamic>> messages = [];

  final List<String> allStyles = [
    "Culture", "Nature", "Adventure", "Relaxation", 
    "Food", "Shopping", "Entertainment"
  ];

  void _generateTravelPlan() async {
    if (destination == null || presentLocation == null || 
        startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'))
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/generate-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'destination': destination,
          'present_location': presentLocation,
          'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
          'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
          'budget': budget,
          'travel_styles': travelStyles.isEmpty ? allStyles : travelStyles,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          travelPlan = data['travel_plan'];
          messages.add({
            'isUser': false,
            'content': travelPlan,
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 300,
            color: const Color(0xFF262730),
            padding: const EdgeInsets.all(16),
            child: _buildSidebar(),
          ),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                if (isLoading) const LinearProgressIndicator(),
                Expanded(child: _buildChatArea()),
                _buildQuestionInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌎 Trip Settings',
          style: TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 20),
        _buildInput('Destination', destination, (val) => setState(() => destination = val)),
        _buildInput('Present Location', presentLocation, 
          (val) => setState(() => presentLocation = val)),
        _buildDatePicker('Start Date', startDate, (date) {
          setState(() => startDate = date);
        }),
        _buildDatePicker('End Date', endDate, (date) {
          setState(() => endDate = date);
        }),
        _buildBudgetSlider(),
        _buildStylesSelector(),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _generateTravelPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('✨ Generate Travel Plan'),
        ),
      ],
    );
  }

  Widget _buildInput(String label, String? value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) onChanged(date);
        },
        child: Text(selectedDate == null 
          ? 'Select $label' 
          : DateFormat('MMM dd, yyyy').format(selectedDate)),
      ),
    );
  }

  Widget _buildBudgetSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budget Level', style: TextStyle(color: Colors.white)),
          Slider(
            value: ['Budget', 'Moderate', 'Luxury'].indexOf(budget).toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            label: budget,
            onChanged: (value) {
              setState(() {
                budget = ['Budget', 'Moderate', 'Luxury'][value.toInt()];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStylesSelector() {
    return Wrap(
      spacing: 8,
      children: allStyles.map((style) {
        final isSelected = travelStyles.contains(style);
        return FilterChip(
          label: Text(style),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                travelStyles.add(style);
              } else {
                travelStyles.remove(style);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF262730),
      child: const Row(
        children: [
          Text('🌎 AI Travel Planner',
            style: TextStyle(fontSize: 24, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Card(
          color: const Color(0xFF262730),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message['content'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Ask a question about your trip...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () async {
              final question = _questionController.text.trim();
              if (question.isEmpty || travelPlan == null) return;

              setState(() => isLoading = true);
              try {
                final response = await http.post(
                  Uri.parse('http://localhost:8000/answer-question'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'question': question,
                    'destination': destination,
                    'travel_plan': travelPlan,
                  }),
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  setState(() {
                    messages.add({
                      'isUser': true,
                      'content': question,
                    });
                    messages.add({
                      'isUser': false,
                      'content': data['answer'],
                    });
                  });
                  _questionController.clear();
                }
              } finally {
                setState(() => isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

