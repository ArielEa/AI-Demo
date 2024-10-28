# app/__init__.py
from flask import Flask

# 创建 Flask 应用实例
app = Flask(__name__)

from app.routes.route import main

app.register_blueprint(main)

# 其他初始化代码可以在这里添加
