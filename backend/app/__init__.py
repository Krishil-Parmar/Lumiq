import os
import firebase_admin
from firebase_admin import credentials, firestore, initialize_app
from flask import Flask
from flask_cors import CORS  # New import for enabling CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Fetch OpenAI API Key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Get absolute path of the backend directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_PATH = os.path.join(BASE_DIR, "..", "lumiq-1c581-firebase-adminsdk-fbsvc-b3ee85c888.json")

# Initialize Firebase (Only Once)
if not firebase_admin._apps:
    cred = credentials.Certificate(JSON_PATH)
    firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()  # 🔥 Define `db` globally

def create_app():
    """Creates and configures the Flask app."""
    app = Flask(__name__)

    # Enable CORS for all routes in the app
    CORS(app)
    
    # Attach Firestore `db` to Flask app
    app.db = db  

    from app.routes import main  # Import routes **after** Firestore is initialized
    app.register_blueprint(main)

    return app