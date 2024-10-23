from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)

CORS(app)

data = {
    "message": "Hello , Py!"
}


@app.route('/api/v1/hello', methods=['GET'])
def hello():
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)