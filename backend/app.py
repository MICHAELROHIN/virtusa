from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configure Gemini API
genai.configure(api_key="AIzaSyAKC1EXSjp7FcgNmI3WFWFQw20tQCiVNmc")
model = genai.GenerativeModel("gemini-pro")

@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json()
    user_input = data.get("message", "")

    if not user_input:
        return jsonify({"response": "No message provided!"})

    response = model.generate_content(user_input)
    return jsonify({"response": response.text})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
