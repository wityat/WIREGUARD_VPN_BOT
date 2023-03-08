import logging

from aiogram import Bot, Dispatcher, executor, types
import subprocess
import os


from aiogram.types import InputFile

API_TOKEN = 'ADD TOKEN HERE!!!'

# Configure logging
logging.basicConfig(level=logging.INFO)

# Initialize bot and dispatcher
bot = Bot(token=API_TOKEN)
dp = Dispatcher(bot)

@dp.message_handler(commands=['start', 'help'])
async def send_welcome(message: types.Message):
    """
    This handler will be called when user sends `/start` or `/help` command
    """
    await message.reply("Hi!\nI'm EchoBot!\nPowered by aiogram.")

@dp.message_handler(commands=['add_friend'])
async def send_welcome(message: types.Message):
    friend_name = message.get_args().split()[0]
    file_path = os.path.realpath(__file__).replace("/bot.py", "")
    bashCommand = f"{file_path}/add_friend.sh " + friend_name + " 51829"
    process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()
    print(output.decode("utf-8").split("\n"))
    photo_path, document_path, _ = output.decode("utf-8").split("\n")
    photo = InputFile(photo_path)
    document = InputFile(document_path)
    await message.reply_photo(photo)
    await message.reply_document(document)

if __name__ == '__main__':
    executor.start_polling(dp, skip_updates=True)
