# app/routes/route.py
import json
import os

from flask import Blueprint, request, jsonify
from flask_cors import CORS

from . import Database

main = Blueprint('main', __name__)

CORS(main)


# 非指定路由，只有文件控制路由，并且只有cache进行存储，没有cache就重新制定cache， 默认存储在var/tmp文件下
@main.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE"])
@main.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE"])
def routes(path):
    return set_route(path)


def set_route(path):
    sql_connector = Database("select * from product;")

    sql_connector.query_database()

    environment = dict(os.environ)

    environment_json = json.dumps(environment, indent=4)

    current_env = os.getenv('FLASK_ENV', 'development')

    data = jsonify({
        'message': 'Hello, this is an anonymous route!',
        'path': path,
        'dir': 'root/main',
        'environment': current_env,
        'method': request.method
    })

    return data


def test_line():
    pass
