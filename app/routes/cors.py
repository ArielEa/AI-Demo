from flask_cors import CORS


def set_cors_request(main):
    CORS(main)
