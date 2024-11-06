# app/routes/route.py
from flask import Blueprint, request, jsonify
from flask_cors import CORS

from . import Database

main = Blueprint('main', __name__)

CORS(main)


@main.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE"])
@main.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE"])
def routes(path):
    return set_route(path)


def set_route(path):
    sql_connector = Database("select * from product;")

    sql_connector.query_database()

    data = jsonify({
        'message': 'Hello, this is an anonymous route!',
        'path': path,
        'dir': 'root/main',
        'method': request.method
    })

    return data


def test_line():
    pass
