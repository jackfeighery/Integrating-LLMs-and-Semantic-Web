import os
from dotenv import load_dotenv
from pathlib import Path
import sys
import json
import re
import logging

# sys.stderr = open(os.devnull, 'w')  # Redirect stderr to devnull to suppress verbose logging output

load_dotenv()

model_rep_path = Path(os.getenv("MODEL_REP_PATH"))

from llama_cpp import Llama

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

stops = ['\n']  # Define custom stop words here

models = [
    # hugging-quants
    {
        "name": "hugging-quants/Llama-3.2-1B-Instruct-Q8_0-GGUF/llama-3.2-1b-instruct-q8_0.gguf",
        "eos": ['\n', '</s>']
    },
    {
        "name": "hugging-quants/Llama-3.2-3B-Instruct-Q8_0-GGUF/llama-3.2-3b-instruct-q8_0.gguf",
        "eos": ['\n', '</s>']
    },
    # thesus-research
    {
        "name": "theseus-research/llama-3.1-8b-prime-kg-exp-1-gguf/llama-3-1-8B-graph-128k.Q4_K_M.gguf",
        "eos": ['\n', '</s>']
    },
    # lmstudio-community
    {
        "name": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
        "eos": ['\n', '</s>']
    },
    # bartowski
    {
        "name": "bartowski/phi-4-GGUF/phi-4-Q4_K_M.gguf",
        "eos": ['\n', '</s>']
    },
    {
        "name": "bartowski/gemma-2-9b-it-GGUF/gemma-2-9b-it-Q4_K_M.gguf",
        "eos": ['\n', '</s>']
    },
    # Qwen
    {
        "name": "Qwen/Qwen2.5-7B-Instruct-GGUF/qwen2.5-7b-instruct-q4_k_m-00001-of-00002.gguf",
        "eos": ['\n', '</s>']
    },
    # MaziyarPanahi
    {
        "name": "MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF/Mistral-7B-Instruct-v0.3.Q4_K_M.gguf",
        "eos": ['\n', '</s>']
    }
]

try:
    with open('prompts.json', 'r') as f:
        prompts = json.load(f)
except FileNotFoundError as e:
    logger.error(f"File not found: {e}")
    sys.exit(1)
except json.JSONDecodeError as e:
    logger.error(f"Error decoding JSON: {e}")
    sys.exit(1)

results_file = 'results.json'

def get_first_line(text):
    for line in text.split('\n'):
        if line.strip(): 
            return line
    return "" 

def clean_text(text):
    '''Function to clean the output and expected answer.'''
    text = re.split(r'\.', text, 1)[0]
    return re.sub(r'\s+', ' ', text).strip().lower()

results = []

for model in models:
    model_path = model_rep_path / model["name"]

    try:
        llm = Llama(
            model_path=str(model_path),
            n_ctx=1024,  # Context length to use
            # n_threads=12,  # Number of CPU threads to use
            # n_gpu_layers=0  # Number of model layers to offload to GPU
        )
    except Exception as e:
        logger.error(f"Error loading model '{model['name']}': {e}")
        continue

    logger.info(f"Testing Model: '{model['name']}'.")

    generation_kwargs = {
        "max_tokens": 50,  # Max number of tokens to generate - reduced to stop models explaining
        # "stop": model["eos"],  # End of sequence tokens to stop the generation process
        "echo": False,  # Echo the prompt in the output
        "temperature": 0.1,  # Temperature to be applied to the model
        "top_k": 1  # Top-k parameter to be applied to the model
    }

    # Loop through the prompts and run inference
    for prompt_data in prompts:
        logger.info(f"\tTesting Prompt: '{prompt_data['name']}'.")

        try:
            result = llm(prompt_data["prompt"], **generation_kwargs)  
            output = get_first_line(result["choices"][0]["text"]) # answer
        except Exception as e:
            logger.error(f"Error generating result for prompt '{prompt_data['name']}': {e}")
            continue

        is_correct = clean_text(output) == clean_text(prompt_data['expected_answer'])

        result_dict = {
            "model": model['name'],
            "prompt_name": prompt_data['name'],
            "output": output,
            "expected_answer": prompt_data['expected_answer'],
            "expected_subject": prompt_data['expected_subject'],
            "expected_property": prompt_data['expected_property'],
            "expected_object": prompt_data['expected_object'],
            "is_correct": 1 if is_correct else 0
        }

        results.append(result_dict)

try:
    with open(results_file, 'w') as file:
        json.dump(results, file, indent=4)
    logger.info(f"Results saved to '{results_file}'.")
except Exception as e:
    logger.error(f"Error saving results to '{results_file}': {e}")
