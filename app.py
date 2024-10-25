from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)

CORS(app)


@app.route('/', defaults={'path':''}, methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def hello(path):
    return jsonify(
        {
            'message': 'Hello, this is an anonymous route!',
            'path': path,
            'dir': 'root/main'
        }
    )


with app.app_context():
    for rule in app.url_map.iter_rules():
        print(f"Endpoint: {rule.endpoint}, Route: {rule.rule}")


if __name__ == '__main__':
    app.run(debug=True)