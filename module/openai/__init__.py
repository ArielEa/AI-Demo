# app.module.openai
from openai import OpenAI
import os


class Open_init:
    def __init__(self):
        pass


    def setter_configuration(self):
        openai = OpenAI()

        openai.api_key = os.getenv("OPENAI_API_KEY")

        completions = openai.chat.completions.create(
            # model="gpt-4o-mini",
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are helpful assistant!"},
                {
                    "role": "user",
                    "content": "Write a haiku about recursion in programing."
                }
            ]
        )

        return completions.choices[0].message


# openai = Open_init()
#
# try:
#     message = openai.setter_configuration()
#
#     print(message)
# except Exception as e:
#     print(f"openai error: {e}")
