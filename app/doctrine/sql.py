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

        self.cursor = self.connection.cursor(dictionary=True)

    def query_database(self):
        self.cursor.execute(self.query)

        results = self.cursor.fetchall()

        try:
            for row in results:
                print(row)

        except Exception as e:
            print(f"SQL error warning: can\'t search column {e}")
            return

        return results

    def close(self):
        self.cursor.close()
        self.connection.close()
