const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Define the Travel Preferences, QuestionRequest, and ModifyRequest models
class TravelPreferences {
  constructor(destination, present_location, start_date, end_date, budget, travel_styles) {
    this.destination = destination;
    this.present_location = present_location;
    this.start_date = new Date(start_date);
    this.end_date = new Date(end_date);
    this.budget = budget;
    this.travel_styles = travel_styles;
  }
}

class QuestionRequest {
  constructor(question, destination, travel_plan) {
    this.question = question;
    this.destination = destination;
    this.travel_plan = travel_plan;
  }
}

class ModifyRequest {
  constructor(travel_plan, modifications) {
    this.travel_plan = travel_plan;
    this.modifications = modifications;
  }
}

// Travel Agent class to interact with the AI agent (using external API like OpenAI or custom logic)
class TravelAgent {
  constructor() {
    this.agent = {
      name: 'Comprehensive Travel Assistant',
      model: 'llama-3.3-70b-versatile', // Just an identifier placeholder
      tools: ['DuckDuckGo', 'SerpApiTools'],
      instructions: [
        'You are a comprehensive travel planning assistant with expertise in all aspects of travel.',
        'For every recommendation and data point, you MUST provide working source links.',
        'Your knowledge spans across:',
        '- Seasonal travel timing and weather patterns',
        '- Transportation options and booking',
        '- Accommodation recommendations',
        '- Day-by-day itinerary planning',
        '- Local cuisine and restaurant recommendations',
        '- Practical travel tips and cultural advice',
        '- Budget estimation and cost breakdown',
        'Format all responses in markdown with clear headings (##) and bullet points.',
        'Use [text](url) format for all hyperlinks.',
        'Verify all links are functional before including them.',
        'Organize information clearly with appropriate sections based on the query type.',
      ],
    };
  }

  async generateTravelPlan(preferences) {
    // Here we would call an external AI service (like OpenAI, or a custom solution) to generate the travel plan.
    const prompt = `Act as a Personalized Travel Expert. Design a comprehensive itinerary for a trip to ${preferences.destination} spanning ${Math.floor((preferences.end_date - preferences.start_date) / (1000 * 60 * 60 * 24))} days, starting on ${preferences.start_date} and ending on ${preferences.end_date}.
    Traveler Preferences:
    Budget Level: ${preferences.budget}
    Travel Styles: ${preferences.travel_styles.join(', ')}`;

    try {
      // Assume the response from the agent is simulated here, in a real app you would call an API like OpenAI
      const response = await axios.post('/generate-plan', { prompt });
      return response.data; // Assuming the response returns a 'content' field or similar.
    } catch (err) {
      console.error('Error generating travel plan:', err);
      throw new Error('Error generating travel plan');
    }
  }

  async answerQuestion(request, preferences) {
    const prompt = `Using the context of this travel plan for ${preferences.destination}: ${request.travel_plan} Please answer this specific question: ${request.question}`;
    try {
      // Simulate calling the agent API
      const response = await axios.post('/answer-question', { prompt });
      return response.data;
    } catch (err) {
      console.error('Error answering question:', err);
      throw new Error('Error answering question');
    }
  }

  async modifyPlan(request) {
    const prompt = `Modify the following travel plan based on the specified changes:
    Original Travel Plan: ${request.travel_plan}
    Modifications: ${request.modifications}`;

    try {
      const response = await axios.post('/modify-plan', { prompt });
      return response.data;
    } catch (err) {
      console.error('Error modifying plan:', err);
      throw new Error('Error modifying plan');
    }
  }
}

// Initialize the TravelAgent
const travelAgent = new TravelAgent();

// Routes
app.get('/', (req, res) => {
  res.send('Hi');
});

app.post('/generate-plan', async (req, res) => {
  try {
    const preferences = new TravelPreferences(req.body.destination, req.body.present_location, req.body.start_date, req.body.end_date, req.body.budget, req.body.travel_styles);
    const travelPlan = await travelAgent.generateTravelPlan(preferences);
    res.json({ travel_plan: travelPlan });
  } catch (error) {
    res.status(500).json({ detail: error.message });
  }
});

app.post('/answer-question', async (req, res) => {
  try {
    const requestData = new QuestionRequest(req.body.question, req.body.destination, req.body.travel_plan);
    const preferences = new TravelPreferences(req.body.destination, '', '', '', '', []); // Assuming the request holds these preferences
    const answer = await travelAgent.answerQuestion(requestData, preferences);
    res.json({ answer });
  } catch (error) {
    res.status(500).json({ detail: error.message });
  }
});

app.post('/modify-plan', async (req, res) => {
  try {
    const modifyRequest = new ModifyRequest(req.body.travel_plan, req.body.modifications);
    const modifiedPlan = await travelAgent.modifyPlan(modifyRequest);
    res.json({ modified_plan: modifiedPlan });
  } catch (error) {
    res.status(500).json({ detail: error.message });
  }
});

// Start the server
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Server running on http:\/\/localhost:${PORT}`);
});
