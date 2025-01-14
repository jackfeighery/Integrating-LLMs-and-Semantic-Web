import os
from dotenv import load_dotenv
from pathlib import Path
import sys
import json
import re

# Redirect stderr to devnull to suppress verbose logging output
sys.stderr = open(os.devnull, 'w')

load_dotenv()

model_rep_path = Path(os.getenv("MODEL_REP_PATH"))

from llama_cpp import Llama

stops = ['\n']  # Define custom stop words here
# SIDE: adding \n char as stop does cause it to stop explaining, but not instantaneously there seems to be delay with some of next lines still being outputted hence the get_first_line func

models = [
    # hugging-quants
    {
        "name": "hugging-quants/Llama-3.2-1B-Instruct-Q8_0-GGUF/llama-3.2-1b-instruct-q8_0.gguf",
        "eos": stops + ['</s>']
    },
    {
        "name": "hugging-quants/Llama-3.2-3B-Instruct-Q8_0-GGUF/llama-3.2-3b-instruct-q8_0.gguf",
        "eos": stops + ['</s>']
    },
    # thesus-research
    {
        "name": "theseus-research/llama-3.1-8b-prime-kg-exp-1-gguf/llama-3-1-8B-graph-128k.Q4_K_M.gguf",
        "eos": stops + ['</s>']
    },
    # lmstudio-community
    {
        "name": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
        "eos": stops + ['</s>']
    }
]

with open('prompts.json', 'r') as f:
    prompts = json.load(f)

def get_first_line(text):
    for line in text.split('\n'):
        if line.strip(): 
            return line
    return "" 

# Function to clean the output and expected answer
def clean_text(text):
    # remove everything after the first period (.) and remove the period itself, to address issue of models adding letters after answer.
    text = re.split(r'\.', text, 1)[0]
    # get rid of whitespace and convert to lowercase
    return re.sub(r'\s+', ' ', text).strip().lower()


for model in models:
    model_path = model_rep_path / model["name"]

    # Instantiate model from the downloaded GGUF file
    llm = Llama(
        model_path=str(model_path),
        n_ctx=1024,  # Context length to use
        # n_threads=12,  # Number of CPU threads to use
        # n_gpu_layers=0  # Number of model layers to offload to GPU
    )
    print(f"==== ==== Loaded the model '{model['name']}'.")



    generation_kwargs = {
        "max_tokens": 50,  # Max number of tokens to generate - reduced to stop models explaining
        # "stop": model["eos"],  # End of sequence tokens to stop the generation process
        "echo": False,  # Echo the prompt in the output
        "temperature": 0.1,  # Temperature to be applied to the model
        "top_k": 1  # Top-k parameter to be applied to the model
    }


    # Loop through the prompts and run inference
    for prompt_data in prompts:
        prompt = prompt_data["prompt"]

        result = llm(prompt, **generation_kwargs)  
        output = get_first_line(result["choices"][0]["text"]) # answer
        print(f"\n{output}\n")
        # print(result["choices"][0]["text"])

        print(f"Expected Answer: {prompt_data['expected_answer']}")
        print(f"Expected Subject: {prompt_data['expected_subject']}")
        print(f"Expected Property: {prompt_data['expected_property']}")
        print(f"Expected Object: {prompt_data['expected_object']}")

        is_correct = clean_text(output) == clean_text(prompt_data['expected_answer'])
        # print(f"\n{clean_text(output)}\n")
        # print(f"\n{clean_text(prompt_data['expected_answer'])}\n")
        # I was having a lot of issues determining correctness due to unexpected spaces and characters. Normalization func is an attempt to battle this
        print(f"Is the model's response correct? {'1' if is_correct else '0'}")



