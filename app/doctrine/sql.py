import mysql.connector


def sql_connector():
    connection = mysql.connector.connect(
        host="rm-6we2wyys0kq07z85iuo.mysql.japan.rds.aliyuncs.com",
        user="ariel6737",
        password="Eternal_673770",
        database="project"
    )

    cursor = connection.cursor()

    cursor.execute("select * from product;")

    results = cursor.fetchall()

    for row in results:
        print(row)
        print(1234)

    cursor.close()

    connection.close()
