import mysql.connector


class Database:
    def __init__(self, query):
        self.query = query
        self.connection = mysql.connector.connect(
            host="rm-6we2wyys0kq07z85iuo.mysql.japan.rds.aliyuncs.com",
            user="ariel6737",
            password="Eternal_673770",
            database="project"
        )

        self.cursor = self.connection.cursor()

    def query_database(self, name):

        print(name)
        self.cursor.execute(self.query)
        results = self.cursor.fetchall()
        for row in results:
            print(row)
            print(1234)
        return results

    def close(self):
        self.cursor.close()
        self.connection.close()
