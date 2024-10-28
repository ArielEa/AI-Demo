# app/routes/route.py
from flask import Blueprint, request, jsonify

main = Blueprint('main', __name__)


@main.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE"])
@main.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE"])
def routes(path):
    return set_route(path)


def set_route(path):
    return jsonify({
        'message': 'Hello, this is an anonymous route!',
        'path': path,
        'dir': 'root/main',
        'method': request.method
    })

