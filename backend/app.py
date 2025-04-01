import google.generativeai as genai
from flask import Flask, request, jsonify

genai.configure(api_key="AIzaSyAKC1EXSjp7FcgNmI3WFWFQw20tQCiVNmc")

app = Flask(__name__)

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_message = data.get("message", "")

    try:
        model = genai.GenerativeModel('gemini-1.5-pro')  # Update model name
        response = model.generate_content(user_message)

        return jsonify({"response": response.text})

    except Exception as e:
        return jsonify({"response": f"Error: {str(e)}"})

if __name__ == '__main__':
    app.run(debug=True)


