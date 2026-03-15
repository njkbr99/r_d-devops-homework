import anthropic
import logging
import time
from flask import Flask, request, jsonify

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
client = anthropic.Anthropic()

SYSTEM_PROMPT = """You are a helpful customer support assistant.
Answer questions clearly and concisely.
If you don't know something, say so honestly."""

def ask_with_retry(question: str, max_retries: int = 3, timeout: int = 30) -> str:
    for attempt in range(max_retries):
        try:
            logger.info(f"Sending question to Claude (attempt {attempt + 1}): {question}")
            message = client.messages.create(
                model="claude-haiku-4-5-20251001",
                max_tokens=1024,
                timeout=timeout,
                system=SYSTEM_PROMPT,
                messages=[{"role": "user", "content": question}]
            )
            answer = message.content[0].text
            logger.info(f"Received answer: {answer[:100]}...")
            return answer
        except Exception as e:
            logger.warning(f"Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json()
    if not data or 'question' not in data:
        return jsonify({"error": "Missing 'question' field"}), 400

    question = data['question']
    logger.info(f"Received question: {question}")

    try:
        answer = ask_with_retry(question)
        return jsonify({"answer": answer})
    except Exception as e:
        logger.error(f"Failed to get answer: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8030)