from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
from pydantic import BaseModel
from typing import List
from datetime import date
from phi.agent import Agent
from phi.model.groq import Groq
from phi.tools.serpapi_tools import SerpApiTools
from phi.tools.duckduckgo import DuckDuckGo
import os
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

app = Flask(__name__)

# Enable CORS for the app
CORS(app)

class TravelPreferences(BaseModel):
    destination: str
#     present_location: str
    start_date: str
    end_date: str
    budget: str
    travel_styles: List[str]

class QuestionRequest(BaseModel):
    question: str
    destination: str
    travel_plan: str

class ModifyRequest(BaseModel):
    travel_plan: str
    modifications: str

class TravelAgent:
    def __init__(self):
        self.agent = Agent(
            name="Comprehensive Travel Assistant",
            model=Groq(id="llama-3.3-70b-versatile"),
            tools=[DuckDuckGo(), SerpApiTools()],
            instructions=[
                "You are a comprehensive travel planning assistant with expertise in all aspects of travel.",
                "For every recommendation and data point, you MUST provide working source links.",
                "Your knowledge spans across:",
                "- Seasonal travel timing and weather patterns",
                "- Transportation options and booking",
                "- Accommodation recommendations",
                "- Day-by-day itinerary planning",
                "- Local cuisine and restaurant recommendations",
                "- Practical travel tips and cultural advice",
                "- Budget estimation and cost breakdown",
                "Format all responses in markdown with clear headings (##) and bullet points.",
                "Use [text](url) format for all hyperlinks.",
                "Verify all links are functional before including them.",
                "Organize information clearly with appropriate sections based on the query type.",
            ],
        )

    def generate_travel_plan(self, preferences: TravelPreferences) -> str:
        date1 = datetime.strptime(preferences.start_date, "%b %d, %Y")
        date2 = datetime.strptime(preferences.end_date, "%b %d, %Y")
        date1_formatted = date1.strftime('%Y-%m-%d')
        date2_formatted = date2.strftime('%Y-%m-%d')

        prompt = f"""Act as a Personalized Travel Expert
You are a travel expert specializing in creating tailored, detailed travel plans. Design a comprehensive itinerary for a trip to {preferences.destination} spanning {date2 - date1}.days days, starting on {preferences.start_date} and ending on {preferences.end_date}.

Traveler Preferences:
Budget Level: {preferences.budget}
Travel Styles: {', '.join(preferences.travel_styles)}
...
"""
        response = self.agent.run(prompt)
        return response.content if hasattr(response, 'content') else str(response)

    def answer_question(self, request: QuestionRequest, preferences: TravelPreferences) -> str:
        prompt = f"""Using the context of this travel plan for {preferences.destination}:

{request.travel_plan}

Please answer this specific question: {request.question}

Guidelines for your response:
1. Focus specifically on answering the question asked
2. Reference relevant parts of the travel plan when applicable
3. Provide new information if the travel plan doesn't cover the topic
4. Include verified source links for any new information
5. Keep the response concise but comprehensive
6. Use markdown formatting for clarity

Format your response with appropriate headings and verify all included links."""
        response = self.agent.run(prompt)
        return response.content if hasattr(response, 'content') else str(response)

    def modify_plan(self, request: ModifyRequest) -> str:
        prompt = f"""Modify the following travel plan based on the specified changes:

Original Travel Plan:
{request.travel_plan}

Modifications:
{request.modifications}

Guidelines:
1. Integrate changes seamlessly into the existing plan.
2. Maintain the original structure and formatting.
3. Provide source links for any new information added.
4. Ensure all details are accurate and up-to-date.

Return the updated travel plan in markdown format."""
        response = self.agent.run(prompt)
        return response.content if hasattr(response, 'content') else str(response)


travel_agent = TravelAgent()

@app.route('/')
def home_page():
    return 'Hi'

@app.route("/generate-plan", methods=["POST"])
def generate_plan():
    try:
        preferences = TravelPreferences(**request.json)
        travel_plan = travel_agent.generate_travel_plan(preferences)
        return jsonify({"travel_plan": travel_plan})
    except Exception as e:
        return jsonify({"detail": str(e)}), 500

@app.route("/answer-question", methods=["POST"])
def answer_question():
    try:
        request_data = QuestionRequest(**request.json)
        preferences = TravelPreferences(**request_data.dict())
        answer = travel_agent.answer_question(request_data, preferences)
        return jsonify({"answer": answer})
    except Exception as e:
        return jsonify({"detail": str(e)}), 500

@app.route("/modify-plan", methods=["POST"])
def modify_plan():
    try:
        modify_request = ModifyRequest(**request.json)
        modified_plan = travel_agent.modify_plan(modify_request)
        return jsonify({"modified_plan": modified_plan})
    except Exception as e:
        return jsonify({"detail": str(e)}), 500


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000)  # Allow external traffic
