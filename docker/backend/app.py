from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow frontend to call backend APIs

@app.route("/", methods=["GET"])
def health_check():
    return jsonify({
        "status": "Backend is running",
        "service": "Shareef Agro Drone Backend"
    })

@app.route("/api/services", methods=["GET"])
def get_services():
    services = [
        "Drone Crop Spraying",
        "Field Mapping",
        "Crop Health Monitoring",
        "Precision Agriculture"
    ]
    return jsonify({
        "services": services
    })

@app.route("/api/about", methods=["GET"])
def about():
    return jsonify({
        "company": "Shareef Agro Drone Services",
        "mission": "Smart farming with modern drone technology"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
