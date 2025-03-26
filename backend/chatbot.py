from chatterbot import ChatBot
from chatterbot.trainers import ChatterBotCorpusTrainer

chatbot = ChatBot("MyChatBot")
trainer = ChatterBotCorpusTrainer(chatbot)

trainer.train("chatterbot.corpus.english")

def get_response(text):
    return str(chatbot.get_response(text))
