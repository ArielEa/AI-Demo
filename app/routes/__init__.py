# app/routes/__init__.py
# 这个文件可以留空，也可以进行一些导入

from app.doctrine.sql import Database

from module.openai import Open_init


def sql_connector_explain():
    open_init = Open_init()

    open_init.setter_configuration()

    return

sql_connector_explain()