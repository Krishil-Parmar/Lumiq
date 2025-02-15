from flask import Blueprint, request, jsonify, current_app
from firebase_admin import auth
from google.cloud import firestore_v1 as firestore
from google.cloud.firestore import SERVER_TIMESTAMP
import requests
import datetime
from dateutil.relativedelta import relativedelta
import openai
from collections import defaultdict
import random
import json
import re
import yfinance as yf
import os
from app import create_app

main = Blueprint('main', __name__)



# Firebase Web API Key (Replace with your actual key from Firebase Console)
FIREBASE_WEB_API_KEY = "AIzaSyAG9cKcb0Y7dGt5sHB3SSMd3eM61K2KvWo"
# Load API Key from Environment Variables
openai_api_key = os.getenv("OPENAI_API_KEY", "your_actual_openai_api_key")
# Initialize OpenAI Client
client = openai.OpenAI(api_key=openai_api_key)



@main.route('/')
def home():
    return {"message": "Lumiq Backend is Running!"}


@main.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400

        # Create user in Firebase
        user = auth.create_user(email=email, password=password)

        return jsonify({
            "message": "User created successfully",
            "uid": user.uid,
            "email": user.email
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@main.route('/signin', methods=['POST'])
def signin():
    try:
        data = request.get_json()
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400

        # Firebase REST API endpoint for sign-in
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
        
        # Request body
        payload = {
            "email": email,
            "password": password,
            "returnSecureToken": True
        }

        # Make request to Firebase
        response = requests.post(url, json=payload)
        result = response.json()

        # Handle response
        if "idToken" in result:
            return jsonify({
                "message": "Sign-in successful",
                "uid": result["localId"],
                "email": result["email"],
                "id_token": result["idToken"],  # Firebase authentication token
                "refresh_token": result["refreshToken"]
            }), 200
        else:
            return jsonify({"error": result.get("error", {}).get("message", "Invalid credentials")}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ✅ Predefined categories
categories = [
    "Food & Dining", "Groceries", "Transport & Fuel", "Shopping & Retail",
    "Health & Medical", "Entertainment", "Bills & Utilities",
    "Rent", "Education", "Investment", "Savings", "Travel & Hotels",
    "Subscriptions", "Personal Care", "EMIs", "Miscellaneous"
]

@main.route('/add_transaction', methods=['POST'])
def add_transaction():
    try:
        data = request.json
        uid = data.get("uid")
        amount = data.get("amount")
        merchant = data.get("merchant", "Unknown Merchant")
        bank = data.get("bank", "Unknown Bank")
        message = data.get("message", "")

        if not uid or not amount or not merchant:
            return jsonify({"error": "User ID, amount, and merchant are required"}), 400

        # ✅ **Automatically Determine Transaction Type**
        transaction_type = "Debit"
        credit_keywords = ["credited", "received", "salary", "deposit", "income"]
        debit_keywords = ["debited", "spent", "withdrawn", "transfer", "payment", "purchase"]

        message_lower = message.lower()

        if any(word in message_lower for word in credit_keywords):
            transaction_type = "Credit"
        elif any(word in message_lower for word in debit_keywords):
            transaction_type = "Debit"

        # ✅ **AI-Based Categorization (Only for Debit Transactions)**
        category = "Miscellaneous"  # Default
        if transaction_type == "Debit":
            category = categorize_transaction_with_ai(merchant, amount)

        # ✅ **Store transaction in Firestore**
        db = current_app.db
        transaction_ref = db.collection("users").document(uid).collection("transactions").document()

        transaction_ref.set({
            "amount": amount,
            "merchant": merchant,
            "category": category,
            "bank": bank,
            "type": transaction_type,
            "timestamp": datetime.datetime.utcnow()  # ✅ Python timestamp
        })

        return jsonify({
            "message": "Transaction added successfully",
            "category": category,
            "type": transaction_type
        }), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500


def categorize_transaction_with_ai(merchant, amount):
    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": f"You are a finance assistant that categorizes transactions into these predefined categories: {', '.join(categories)}. Only return the category name from this list, nothing else."},
                {"role": "user", "content": f"Classify this transaction: Merchant={merchant}, Amount={amount}"}
            ],
            temperature=0.1,
            max_tokens=10
        )

        category = response.choices[0].message.content.strip()

        # ✅ Ensure AI response is in predefined categories
        if category not in categories:
            print(f"⚠️ AI returned an unknown category: {category}. Defaulting to 'Miscellaneous'.")
            return "Miscellaneous"

        return category

    except Exception as e:
        print(f"⚠️ AI Categorization Failed: {str(e)}")
        return "Miscellaneous"


@main.route('/get_transactions', methods=['GET'])
def get_transactions():
    try:
        uid = request.args.get("uid")
        category = request.args.get("category")  # Optional filter
        merchant = request.args.get("merchant")  # Optional filter
        start_date = request.args.get("start_date")  # Format: YYYY-MM-DD
        end_date = request.args.get("end_date")  # Format: YYYY-MM-DD

        if not uid:
            return jsonify({"error": "User ID (uid) is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        
        # Apply filters
        query = transactions_ref
        if category:
            query = query.where("category", "==", category)
        if merchant:
            query = query.where("merchant", "==", merchant)
        if start_date and end_date:
            start_dt = datetime.datetime.strptime(start_date, "%Y-%m-%d")
            end_dt = datetime.datetime.strptime(end_date, "%Y-%m-%d") + datetime.timedelta(days=1)
            query = query.where("timestamp", ">=", start_dt).where("timestamp", "<", end_dt)

        # Fetch transactions
        transactions = query.stream()
        transactions_list = [
            {**t.to_dict(), "id": t.id} for t in transactions
        ]

        return jsonify({"transactions": transactions_list}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/auto_categorize', methods=['POST'])
def auto_categorize():
    try:
        data = request.get_json()
        merchant = data.get("merchant")
        amount = data.get("amount")

        if not merchant or not amount:
            return jsonify({"error": "Merchant and amount are required"}), 400

        # Predefined categories for classification
        categories = [
            "Food & Dining", "Groceries", "Transport & Fuel", "Shopping & Retail",
            "Health & Medical", "Entertainment", "Bills & Utilities",
            "Rent", "Education", "Investment", "Savings", "Travel & Hotels",
            "Subscriptions", "EMIs", "Miscellaneous"
        ]

        # OpenAI GPT-4o API Call for Categorization (Updated Syntax)
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": f"You are a finance assistant that categorizes transactions into these predefined categories: {', '.join(categories)}."},
                {"role": "user", "content": f"Classify this transaction: Merchant={merchant}, Amount={amount}. Return only the category name."}
            ]
        )

        # Extract AI response
        category = response.choices[0].message.content.strip()

        # Ensure category matches predefined list
        if category not in categories:
            category = "Miscellaneous"  # Default category if AI gives an unexpected response

        return jsonify({"merchant": merchant, "amount": amount, "category": category}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/spending_summary', methods=['GET'])
def spending_summary():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID (uid) is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")

        transactions = transactions_ref.stream()

        # Aggregate spending by category
        category_totals = defaultdict(float)
        total_spent = 0

        for transaction in transactions:
            data = transaction.to_dict()
            category = data.get("category", "Uncategorized")
            amount = data.get("amount", 0)
            category_totals[category] += amount
            total_spent += amount

        # Format response
        summary = {
            "total_spent": total_spent,
            "category_breakdown": dict(category_totals)
        }

        return jsonify(summary), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_spending_trends', methods=['GET'])
def get_spending_trends():
    try:
        uid = request.args.get("uid")
        period = request.args.get("period", "monthly")  # Default to monthly

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        # Define the time range based on period type
        end_date = datetime.datetime.utcnow()
        if period == "weekly":
            start_date = end_date - datetime.timedelta(weeks=1)
        elif period == "monthly":
            start_date = end_date - relativedelta(months=1)
        elif period == "quarterly":
            start_date = end_date - relativedelta(months=3)
        elif period == "yearly":
            start_date = end_date - relativedelta(years=1)
        else:
            return jsonify({"error": "Invalid period. Use weekly, monthly, quarterly, or yearly."}), 400

        # Fetch transactions from Firestore
        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        all_transactions = transactions_ref.stream()

        transactions = []
        for transaction in all_transactions:
            transaction_data = transaction.to_dict()

            # Fix timestamp handling
            timestamp = transaction_data.get("timestamp")
            if timestamp is None:
                continue  # Skip transactions with no timestamp

            if isinstance(timestamp, str):
                try:
                    # Convert string timestamp to a datetime object
                    transaction_data["timestamp"] = datetime.datetime.strptime(timestamp, "%a, %d %b %Y %H:%M:%S %Z")
                except ValueError:
                    # If parsing fails, skip this transaction
                    continue
            elif isinstance(timestamp, datetime.datetime):
                # Ensure the datetime is naive (UTC)
                transaction_data["timestamp"] = timestamp.replace(tzinfo=None)
            else:
                # If timestamp is not recognized, skip this transaction
                continue

            transactions.append(transaction_data)

        # Filter transactions based on the requested period
        filtered_transactions = [
            t for t in transactions if start_date <= t["timestamp"] <= end_date
        ]

        # Aggregate spending by category for Debit transactions
        category_spending = {}
        total_spent = 0
        for transaction in filtered_transactions:
            transaction_type = transaction.get("type", "Unknown")
            if transaction_type == "Debit":  # Only count expenses
                category = transaction.get("category", "Uncategorized")
                amount = transaction.get("amount", 0)
                category_spending[category] = category_spending.get(category, 0) + amount
                total_spent += amount

        return jsonify({
            "total_spent": total_spent,
            "category_breakdown": category_spending
        }), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500


@main.route('/predict_expenses', methods=['GET'])
def predict_expenses():
    try:
        print("🔍 Step 1: Starting API call")  # Debug message

        uid = request.args.get("uid")
        if not uid:
            return jsonify({"error": "User ID (uid) is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        transactions = transactions_ref.stream()

        print("✅ Step 2: Retrieved transactions")  # Debug message

        # Aggregate spending by category per month
        monthly_category_totals = defaultdict(lambda: defaultdict(float))

        for transaction in transactions:
            data = transaction.to_dict()
            category = data.get("category", "Uncategorized")
            amount = data.get("amount", 0)
            timestamp = data.get("timestamp")

            if isinstance(timestamp, datetime.datetime):
                month_year = timestamp.strftime("%Y-%m")  # Format: YYYY-MM (e.g., 2024-01)
            else:
                month_year = "Unknown"

            monthly_category_totals[month_year][category] += amount

        print("✅ Step 3: Aggregated transactions")  # Debug message

        # Convert spending data into a structured format
        structured_data = "\n".join([
            f"{month}: {json.dumps(categories)}"
            for month, categories in sorted(monthly_category_totals.items())
        ])

        print("🔹 Step 4: Sending Data to OpenAI")  # Debug message

        # **AI Call: Get raw prediction response**
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are an AI that predicts future expenses based on monthly spending trends. Always respond with category-wise amounts."},
                {"role": "user", "content": f"Here is the past monthly spending data:\n\n{structured_data}\n\n"
                                            "Predict estimated spending for the next month, listing categories and expected amounts in a simple format.\n\n"
                                            "Example format:\n"
                                            "Food & Dining: 4500\n"
                                            "Transport & Fuel: 7000\n"
                                            "Entertainment: 1200\n\n"
                                            "Do NOT include explanations, comments, or extra text—only return the predicted categories and numbers."}
            ],
            temperature=0,
            max_tokens=300
        )

        raw_prediction = response.choices[0].message.content.strip()

        print(f"📩 Step 5: OpenAI Response Received: {raw_prediction}")  # Debug message

        # **Step 6: Extract key-value pairs using regex**
        predicted_expenses = {}
        lines = raw_prediction.split("\n")
        for line in lines:
            match = re.match(r"(.+?):\s*([\d.]+)", line)
            if match:
                category, amount = match.groups()
                predicted_expenses[category.strip()] = float(amount)

        print(f"✅ Step 6: Extracted Predictions: {predicted_expenses}")  # Debug message

        # If extraction fails, return an error
        if not predicted_expenses:
            return jsonify({"error": "AI returned invalid predictions"}), 500

        return jsonify({"predicted_expenses": predicted_expenses}), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")  # Debug message for errors
        return jsonify({"error": str(e)}), 500

########################################################################################################################

@main.route('/set_budget', methods=['POST'])
def set_budget():
    try:
        data = request.json
        uid = data.get("uid")
        category = data.get("category")
        limit = data.get("limit")  # Can be None if AI should decide

        if not uid or not category:
            return jsonify({"error": "User ID and category are required"}), 400

        # 🔥 Get Firestore instance from Flask app
        db = current_app.db  

        budget_ref = db.collection("budgets").document(uid).collection("categories").document(category)

        # If no limit is provided, get AI-based budget recommendation
        if limit is None:
            start_date = datetime.datetime.utcnow() - datetime.timedelta(days=30)
            transactions = db.collection("transactions").where("uid", "==", uid).where("category", "==", category).stream()
            total_spent = sum(t.to_dict().get("amount", 0) for t in transactions)
            avg_spent = total_spent / 3 if total_spent else 5000  # Default ₹5000 if no data

            # AI-based budget suggestion
            response = openai.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": f"You are a finance assistant helping users set their budget. Based on past spending trends, suggest an ideal budget for the {category} category."},
                    {"role": "user", "content": f"Past spending for {category}: {total_spent} in the last 3 months. Suggest an ideal budget for the next month."}
                ]
            )
            limit = float(response.choices[0].message.content.strip())

        # Store budget in Firestore
        budget_ref.set({
            "limit": limit,
            "last_updated": datetime.datetime.utcnow()
        })

        return jsonify({"message": "Budget set successfully!"}), 200

    except Exception as e:
        print(f"⚠️ Error: {str(e)}")
        return jsonify({"error": str(e)}), 500


@main.route('/get_budget_status', methods=['GET'])
def get_budget_status():
    try:
        uid = request.args.get("uid")
        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db  # Ensure Firestore instance is correctly retrieved

        # Fetch budgets set by the user from the budgets collection
        budget_ref = db.collection("budgets").document(uid).collection("categories")
        budget_docs = budget_ref.stream()

        budgets = []
        for budget in budget_docs:
            budget_data = budget.to_dict()
            category = budget.id  # Category name from document ID
            limit = budget_data.get("limit", 0)

            # Set the start of the month for filtering transactions
            start_date = datetime.datetime.utcnow().replace(day=1)

            # Query transactions from the user's subcollection instead of a top-level collection
            transactions_ref = db.collection("users").document(uid).collection("transactions") \
                .where("category", "==", category) \
                .where("timestamp", ">=", start_date)
            transactions = transactions_ref.stream()

            # Calculate total spent in this category
            total_spent = sum(transaction.to_dict().get("amount", 0) for transaction in transactions)
            percentage_used = (total_spent / limit) * 100 if limit > 0 else 0
            remaining = max(0, limit - total_spent)

            # Trigger AI Alert if budget exceeds 90%
            if percentage_used >= 90:
                print(f"⚠️ AI Alert: Budget for {category} exceeded 90%! Consider reducing expenses.")

            budgets.append({
                "category": category,
                "budget_limit": limit,
                "spent": total_spent,
                "remaining": remaining,
                "percentage_used": round(percentage_used, 2)
            })

        return jsonify({"budgets": budgets}), 200

    except Exception as e:
        print(f"⚠️ Error: {str(e)}")
        return jsonify({"error": str(e)}), 500


########################################################################################################################

@main.route('/add_bank_account', methods=['POST'])
def add_bank_account():
    try:
        data = request.get_json()
        uid = data.get("uid")
        bank_name = data.get("bank_name")
        account_number = data.get("account_number")
        balance = data.get("balance")

        if not uid or not bank_name or not account_number or balance is None:
            return jsonify({"error": "User ID, bank name, account number, and balance are required"}), 400

        db = current_app.db
        account_ref = db.collection("users").document(uid).collection("bank_accounts").document(account_number)

        account_ref.set({
            "bank_name": bank_name,
            "account_number": account_number,
            "balance": balance
        })

        return jsonify({"message": "Bank account added successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_joint_account_total', methods=['GET'])
def get_joint_account_total():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        accounts_ref = db.collection("users").document(uid).collection("bank_accounts")
        accounts_docs = accounts_ref.stream()

        total_balance = 0
        account_details = []

        for doc in accounts_docs:
            account_data = doc.to_dict()
            balance = account_data.get("balance", 0)
            total_balance += balance
            account_details.append(account_data)

        return jsonify({
            "joint_account_total": total_balance,
            "linked_accounts": account_details
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_linked_accounts', methods=['GET'])
def get_linked_accounts():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        accounts_ref = db.collection("users").document(uid).collection("bank_accounts")
        accounts_docs = accounts_ref.stream()

        linked_accounts = [doc.to_dict() for doc in accounts_docs]

        return jsonify({"linked_accounts": linked_accounts}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


########################################################################################################################


def get_full_account_number(uid, masked_number):
    """Maps the masked bank account number (e.g., X7890) to the actual account stored in Firestore."""
    db = current_app.db
    accounts_ref = db.collection("users").document(uid).collection("bank_accounts")
    accounts_docs = accounts_ref.stream()

    for doc in accounts_docs:
        full_account_number = doc.id  # Firestore stores full number as doc ID
        if full_account_number.endswith(masked_number):  # Check if last digits match
            return full_account_number  # Return actual account number

    return None  # No match found

@main.route('/process_sms', methods=['POST'])
def process_sms():
    try:
        data = request.get_json()
        uid = data.get("uid")
        message = data.get("message")

        if not uid or not message:
            return jsonify({"error": "User ID and SMS message are required"}), 400

        print(f"📩 Received SMS: {message}")

        # Extract amount using a pattern that looks for an "Rs" amount anywhere in the message.
        amount_match = re.search(r'Rs\.?\s?(\d+(?:,\d{3})*(?:\.\d+)?)', message, re.IGNORECASE)
        amount = float(amount_match.group(1).replace(',', '')) if amount_match else None

        # Extract merchant name using a pattern that finds text after "to" and before "from" or "on"
        merchant_match = re.search(r'\bto\s+([A-Za-z\s&]+?)(?:\s+from|\s+on|$)', message, re.IGNORECASE)
        merchant = merchant_match.group(1).strip() if merchant_match else "Unknown Merchant"

        # Extract bank account details using a pattern for masked numbers like "A/C X7890"
        bank_match = re.search(r'A/C\sX?(\d{4,5})', message, re.IGNORECASE)
        masked_number = bank_match.group(1) if bank_match else None

        if masked_number:
            matched_account = get_full_account_number(uid, masked_number)
            bank_name = matched_account if matched_account else f"A_C_X{masked_number}"
        else:
            bank_name = "Unknown_Bank"

        # Determine Transaction Type (UPI is always Debit)
        transaction_type = "Debit" if "debited" in message.lower() else "Credit"

        # Ensure valid transaction extraction
        if amount is None or transaction_type == "Unknown":
            print("⚠️ Failed Extraction - Amount:", amount, "Bank:", bank_name)
            return jsonify({"error": "Failed to extract transaction details"}), 400

        # AI-Based Categorization for Debit Transactions
        category = "Income" if transaction_type == "Credit" else "Uncategorized"
        if transaction_type == "Debit":
            ai_response = openai.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "You are an AI that classifies bank transactions. Only return one category from: Food, Shopping, Travel, Bills, Rent, Entertainment, Medical, Investment, Miscellaneous."},
                    {"role": "user", "content": f"Transaction: Rs. {amount} spent on {merchant}. Categorize this into one of the given options."}
                ],
                temperature=0,
                max_tokens=10
            )
            category = ai_response.choices[0].message.content.strip()

        print(f"🔹 Extracted Data - Amount: {amount}, Merchant: {merchant}, Bank: {bank_name}, Type: {transaction_type}, Category: {category}")

        # Firestore Transaction: Store Transaction
        db = current_app.db
        transaction_ref = db.collection("users").document(uid).collection("transactions").document()
        transaction_ref.set({
            "amount": amount,
            "merchant": merchant,
            "bank": bank_name,
            "type": transaction_type,
            "category": category
        })

        # Firestore: Adjust Bank Balance Safely (Even if Balance is Missing)
        bank_ref = db.collection("users").document(uid).collection("bank_accounts").document(bank_name)
        bank_doc = bank_ref.get()

        if bank_doc.exists:
            bank_data = bank_doc.to_dict()
            new_balance = max(0, bank_data["balance"] - amount)  # Prevent negative balance
            bank_ref.update({"balance": new_balance})
        else:
            print(f"⚠️ Bank account '{bank_name}' not found in Firestore. Creating new account entry.")
            bank_ref.set({"bank_name": bank_name, "balance": 0})  # Set balance as 0 since we can't confirm it

        return jsonify({
            "message": "Transaction processed successfully!",
            "amount": amount,
            "merchant": merchant,
            "bank": bank_name,
            "type": transaction_type,
            "category": category
        }), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500


########################################################################################################################

@main.route('/add_upcoming_payment', methods=['POST'])
def add_upcoming_payment():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Payment name (Netflix, Rent, etc.)
        amount = data.get("amount")
        due_date = data.get("due_date")  # Format: YYYY-MM-DD
        auto_debit = data.get("auto_debit", False)

        if not uid or not name or not amount or not due_date:
            return jsonify({"error": "Missing required fields"}), 400

        db = current_app.db
        payment_ref = db.collection("users").document(uid).collection("payments").document(name)

        payment_ref.set({
            "name": name,
            "amount": amount,
            "due_date": due_date,
            "auto_debit": auto_debit
        })

        return jsonify({"message": "Payment added successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_upcoming_payments', methods=['GET'])
def get_upcoming_payments():
    try:
        uid = request.args.get("uid")
        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        payments_ref = db.collection("users").document(uid).collection("payments")
        payments_docs = payments_ref.stream()

        upcoming_payments = []
        for doc in payments_docs:
            upcoming_payments.append(doc.to_dict())

        return jsonify({"upcoming_payments": upcoming_payments}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/delete_upcoming_payment', methods=['DELETE'])
def delete_upcoming_payment():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Name of the payment to delete

        if not uid or not name:
            return jsonify({"error": "User ID and payment name are required"}), 400

        db = current_app.db
        payment_ref = db.collection("users").document(uid).collection("payments").document(name)

        payment_ref.delete()

        return jsonify({"message": "Payment deleted successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/set_auto_debit_reminder', methods=['GET'])
def set_auto_debit_reminder():
    try:
        uid = request.args.get("uid")
        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        payments_ref = db.collection("users").document(uid).collection("payments")
        payments_docs = payments_ref.stream()

        reminders = []
        today = datetime.date.today()

        for doc in payments_docs:
            payment = doc.to_dict()
            due_date = datetime.datetime.strptime(payment["due_date"], "%Y-%m-%d").date()

            # Notify user if auto-debit payment is within 3 days
            if payment["auto_debit"] and (due_date - today).days <= 3:
                reminders.append(payment)

        return jsonify({"auto_debit_reminders": reminders}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


########################################################################################################################

@main.route('/create_goal', methods=['POST'])
def create_goal():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Goal name (e.g., "Save for Vacation")
        target_amount = data.get("target_amount")
        saved_amount = data.get("saved_amount", 0)  # Default to 0

        if not uid or not name or not target_amount:
            return jsonify({"error": "User ID, goal name, and target amount are required"}), 400

        db = current_app.db
        goal_ref = db.collection("users").document(uid).collection("goals").document(name)

        goal_ref.set({
            "name": name,
            "target_amount": target_amount,
            "saved_amount": saved_amount
        })

        return jsonify({"message": "Goal created successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_goals', methods=['GET'])
def get_goals():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        goals_ref = db.collection("users").document(uid).collection("goals")
        goals_docs = goals_ref.stream()

        goals = []
        for doc in goals_docs:
            goals.append(doc.to_dict())

        return jsonify({"goals": goals}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/update_goal_progress', methods=['POST'])
def update_goal_progress():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Goal name
        saved_amount = data.get("saved_amount")  # New saved amount

        if not uid or not name or saved_amount is None:
            return jsonify({"error": "User ID, goal name, and saved amount are required"}), 400

        db = current_app.db
        goal_ref = db.collection("users").document(uid).collection("goals").document(name)

        goal_ref.update({"saved_amount": saved_amount})

        return jsonify({"message": "Goal progress updated successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/delete_goal', methods=['DELETE'])
def delete_goal():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Goal name to delete

        if not uid or not name:
            return jsonify({"error": "User ID and goal name are required"}), 400

        db = current_app.db
        goal_ref = db.collection("users").document(uid).collection("goals").document(name)

        goal_ref.delete()

        return jsonify({"message": "Goal deleted successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

########################################################################################################################

def get_stock_price(symbol):
    """Fetches the latest stock price from Yahoo Finance."""
    try:
        stock = yf.Ticker(symbol)
        return stock.history(period="1d")["Close"].iloc[-1]  # Get the latest closing price
    except Exception as e:
        return None  # Return None if fetching fails

def get_crypto_price(crypto_symbol):
    """Fetches the latest crypto price from CoinGecko."""
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={crypto_symbol}&vs_currencies=usd"
    try:
        response = requests.get(url)
        return response.json().get(crypto_symbol, {}).get("usd", None)
    except Exception as e:
        return None  # Return None if fetching fails


@main.route('/add_investment', methods=['POST'])
def add_investment():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Investment name (Apple, Bitcoin, etc.)
        invested_amount = data.get("invested_amount")
        symbol = data.get("symbol")  # Stock ticker (AAPL) or crypto ID (bitcoin)

        if not uid or not name or not invested_amount or not symbol:
            return jsonify({"error": "User ID, investment name, invested amount, and symbol are required"}), 400

        # Determine if it's a stock or crypto
        if symbol.lower() in ["bitcoin", "ethereum", "dogecoin", "cardano"]:
            current_value = get_crypto_price(symbol.lower())  # Crypto Price
        else:
            current_value = get_stock_price(symbol.upper())  # Stock Price

        if current_value is None:
            return jsonify({"error": "Failed to fetch live price"}), 500

        total_value = invested_amount * (current_value / invested_amount)  # Update value
        percentage_change = ((total_value - invested_amount) / invested_amount) * 100

        db = current_app.db
        investment_ref = db.collection("users").document(uid).collection("investments").document(name)

        investment_ref.set({
            "name": name,
            "invested_amount": invested_amount,
            "current_value": total_value,
            "percentage_change": percentage_change,
            "symbol": symbol
        })

        return jsonify({"message": "Investment added successfully!", "current_value": total_value, "percentage_change": percentage_change}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_investments', methods=['GET'])
def get_investments():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        investments_ref = db.collection("users").document(uid).collection("investments")
        investment_docs = investments_ref.stream()

        investments = []
        for doc in investment_docs:
            investment = doc.to_dict()
            symbol = investment.get("symbol")
            
            # Fetch the latest price
            if symbol.lower() in ["bitcoin", "ethereum", "dogecoin", "cardano"]:
                current_value = get_crypto_price(symbol.lower())
            else:
                current_value = get_stock_price(symbol.upper())

            if current_value:
                investment["current_value"] = current_value
                investment["percentage_change"] = ((current_value - investment["invested_amount"]) / investment["invested_amount"]) * 100
            
            investments.append(investment)

        return jsonify({"investments": investments}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/update_investment', methods=['POST'])
def update_investment():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Investment name
        new_value = data.get("current_value")  # New value provided by user

        if not uid or not name or new_value is None:
            return jsonify({"error": "User ID, investment name, and new value are required"}), 400

        db = current_app.db
        investment_ref = db.collection("users").document(uid).collection("investments").document(name)
        investment_doc = investment_ref.get()

        if not investment_doc.exists:
            return jsonify({"error": "Investment not found"}), 404

        investment_data = investment_doc.to_dict()
        invested_amount = investment_data["invested_amount"]
        percentage_change = ((new_value - invested_amount) / invested_amount) * 100

        # Update investment details
        investment_ref.update({
            "current_value": new_value,
            "percentage_change": percentage_change
        })

        return jsonify({"message": "Investment updated successfully!", "current_value": new_value, "percentage_change": percentage_change}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/get_market_trends', methods=['POST'])
def get_market_trends():
    try:
        data = request.get_json()
        stocks = data.get("stocks", [])  # Example: ["AAPL", "TSLA", "MSFT"]
        cryptos = data.get("cryptos", [])  # Example: ["bitcoin", "ethereum"]

        if not stocks and not cryptos:
            return jsonify({"error": "Please provide at least one stock or crypto symbol"}), 400

        market_trends = {}

        # Fetch stock prices
        for stock in stocks:
            stock_price = get_stock_price(stock.upper())
            if stock_price:
                market_trends[stock.upper()] = stock_price

        # Fetch crypto prices
        for crypto in cryptos:
            crypto_price = get_crypto_price(crypto.lower())
            if crypto_price:
                market_trends[crypto.lower()] = crypto_price

        return jsonify({"market_trends": market_trends}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@main.route('/delete_investment', methods=['DELETE'])
def delete_investment():
    try:
        data = request.get_json()
        uid = data.get("uid")
        name = data.get("name")  # Investment name to delete

        if not uid or not name:
            return jsonify({"error": "User ID and investment name are required"}), 400

        db = current_app.db
        investment_ref = db.collection("users").document(uid).collection("investments").document(name)

        investment_ref.delete()

        return jsonify({"message": "Investment deleted successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500



@main.route('/get_savings_recommendations', methods=['GET'])
def get_savings_recommendations():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        transactions = transactions_ref.stream()

        print("✅ Retrieved transactions from Firestore.")

        # Aggregate spending by category
        category_totals = {}
        for transaction in transactions:
            data = transaction.to_dict()
            category = data.get("category", "Uncategorized")
            amount = data.get("amount", 0)
            category_totals[category] = category_totals.get(category, 0) + amount

        print(f"✅ Spending data: {category_totals}")

        structured_data = json.dumps(category_totals, indent=2)

        if not category_totals:
            return jsonify({"error": "No spending data found. Add some transactions first."}), 400

        # OpenAI GPT-4o API Call for Financial Insights
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are an AI financial advisor that provides cost-saving recommendations based on past spending."},
                {"role": "user", "content": f"Here is the user's spending data:\n\n{structured_data}\n\n"
                                            "Suggest practical ways to reduce unnecessary expenses. "
                                            "Respond in JSON format with key categories and savings suggestions."}
            ],
            temperature=0.5,
            max_tokens=300
        )

        print(f"📩 OpenAI raw response: {response.choices[0].message.content.strip()}")

        ai_response = response.choices[0].message.content.strip()

        # Remove any Markdown-style formatting (` ```json ... ``` `)
        if ai_response.startswith("```json"):
             ai_response = ai_response[7:-3].strip()

        print(f"🛠️ Cleaned AI Response: {ai_response}")  # Debugging log

        # Ensure response is valid JSON
        try:
            recommendations = json.loads(ai_response)
        except json.JSONDecodeError:
            print("❌ AI did not return valid JSON.")
            return jsonify({"error": "AI returned an invalid JSON format"}), 500

        return jsonify({"savings_recommendations": recommendations}), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500


@main.route('/ai_goal_analysis', methods=['GET'])
def ai_goal_analysis():
    try:
        uid = request.args.get("uid")

        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        goals_ref = db.collection("users").document(uid).collection("goals")
        goals_docs = goals_ref.stream()

        goals = []
        for doc in goals_docs:
            goals.append(doc.to_dict())

        if not goals:
            return jsonify({"error": "No financial goals found. Add some goals first."}), 400

        structured_data = json.dumps(goals, indent=2)

        # OpenAI GPT-4o API Call for Goal Planning
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are an AI financial advisor that helps users plan their savings for financial goals. "
                                             "Your response MUST be a valid JSON output."},
                {"role": "user", "content": f"Here is the user's financial goal data:\n\n{structured_data}\n\n"
                                            "Suggest a practical monthly saving strategy for each goal, considering the target amount and current savings. "
                                            "Respond ONLY in JSON format like this:\n\n"
                                            "{ \"goal_name\": { \"monthly_savings_needed\": 5000, \"suggestion\": \"Text advice here\" } }\n\n"
                                            "Do NOT include any explanations, just return a valid JSON object."}
            ],
            temperature=0.5,
            max_tokens=300
        )

        ai_response = response.choices[0].message.content.strip()

        # Remove Markdown-style backticks if present
        if ai_response.startswith("```json"):
            ai_response = ai_response[7:-3].strip()

        print(f"📩 AI Response: {ai_response}")  # Debugging log

        try:
            goal_plan = json.loads(ai_response)
        except json.JSONDecodeError:
            print("❌ AI did not return valid JSON.")
            return jsonify({"error": "AI returned an invalid JSON format"}), 500

        return jsonify({"goal_plan": goal_plan}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


########################################################################################################################



########################################################################################################################
# for backtesting and inserting the data in database with past dates
@main.route('/bulk_add_transactions', methods=['POST'])
def bulk_add_transactions():
    try:
        data = request.get_json()
        uid = data.get("uid")
        num_transactions = data.get("num_transactions", 100)  # Default: 100 transactions

        if not uid:
            return jsonify({"error": "User ID (uid) is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")

        # Predefined categories, merchants, and realistic amounts
        categories = {
            "Food & Dining": ["Zomato", "Swiggy", "McDonald's", "Dominos","Restaurants and Dining"],
            "Groceries": ["Big Bazaar", "Walmart", "Local Market", "Zepto", "Blinkit", "Instamart"],
            "Transport & Fuel": ["Uber", "Ola", "Petrol"],
            "Shopping & Retail": ["Amazon", "Flipkart", "H&M", "Nike", "Zara"],
            "Health & Medical": ["Apollo Pharmacy", "Medlife", "Fortis Hospital"],
            "Entertainment": ["Netflix", "Spotify", "PVR Cinemas","IMAX Cinemas"],
            "Bills & Utilities": ["Electricity Bill", "Water Bill", "Airtel","Gas Bill"],
            "Rent": ["House Rent", "PG Rent"],
            "Education": ["Udemy", "Coursera", "Skillshare", "Childern's Extra Curricular"],
            "Investment": ["Stocks", "Mutual Funds", "Crypto","SIP"],
            "Savings": ["Bank Deposit", "Fixed Deposit","Emergency Fund's Deposit"],
            "Travel & Hotels": ["MakeMyTrip", "Goibibo", "Expedia"],
            "Subscriptions": ["Amazon Prime", "Disney+", "YouTube Premium"],
            "Personal Care": ["Salon", "Health Spa"],
            "EMI's": ["House Loan EMI", "Credit Card Emi"],
            "Miscellaneous": ["Misc Expense", "Unknown"]
        }

        transactions_to_add = []

        # Generate random transactions
        for _ in range(num_transactions):
            category = random.choice(list(categories.keys()))
            merchant = random.choice(categories[category])
            amount = round(random.uniform(50, 5000), 2)  # Random amount
            days_ago = random.randint(10, 180)  # Random date in last 6 months
            timestamp = datetime.datetime.utcnow() - datetime.timedelta(days=days_ago)

            transactions_to_add.append({
                "amount": amount,
                "category": category,
                "merchant": merchant,
                "timestamp": timestamp
            })

        # Batch insert transactions into Firestore
        batch = db.batch()
        for transaction in transactions_to_add:
            transaction_ref = transactions_ref.document()
            batch.set(transaction_ref, transaction)
        batch.commit()

        return jsonify({"message": f"{num_transactions} transactions added successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
########################################################################################################################


@main.route('/debug_transactions', methods=['GET'])
def debug_transactions():
    try:
        uid = request.args.get("uid")
        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        transactions = transactions_ref.stream()

        transaction_list = []
        for transaction in transactions:
            transaction_data = transaction.to_dict()
            transaction_list.append(transaction_data)

        return jsonify({"transactions": transaction_list}), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500




@main.route('/delete_all_transactions', methods=['DELETE'])
def delete_all_transactions():
    try:
        uid = request.args.get("uid")
        if not uid:
            return jsonify({"error": "User ID is required"}), 400

        db = current_app.db
        transactions_ref = db.collection("users").document(uid).collection("transactions")
        transactions = transactions_ref.stream()

        batch = db.batch()
        count = 0
        for transaction in transactions:
            batch.delete(transaction.reference)
            count += 1

        batch.commit()  # Execute the batch delete

        return jsonify({"message": f"{count} transactions deleted successfully!"}), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500