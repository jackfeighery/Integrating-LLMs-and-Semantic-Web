import os
from dotenv import load_dotenv
from pathlib import Path
import sys
import json
import re
import logging
from llama_cpp import Llama
from openai import OpenAI

load_dotenv()


# sys.stderr = open(os.devnull, 'w')  # Redirect stderr to devnull to suppress verbose logging output
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


MODEL_REP_PATH = Path(os.getenv("MODEL_REP_PATH"))
RESULTS_FILE = 'results.json'
PROMPTS_FILE = 'prompts.json'


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


def load_prompts(file_path):
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
        exit(1)
    except json.JSONDecodeError as e:
        logger.error(f"Error decoding JSON: {e}")
        exit(1)

def clean_text(text):
    '''Function to clean the output and expected answer.'''
    text = re.split(r'\.', text, 1)[0]
    return re.sub(r'\s+', ' ', text).strip().lower()

def get_first_line(text):
    for line in text.split('\n'):
        if line.strip(): 
            return line
    return "" 

def save_results(results, file_path):
    try:
        with open(file_path, 'w') as file:
            json.dump(results, file, indent=4)
        logger.info(f"Results saved to '{file_path}'.")
    except Exception as e:
        logger.error(f"Error saving results to '{file_path}': {e}")


def test_models(prompts, models, results):
    for model in models:
        model_path = MODEL_REP_PATH / model["name"]
        try:
            llm = Llama(model_path=str(model_path), n_ctx=4096)
        except Exception as e:
            logger.error(f"Error loading model '{model['name']}': {e}")
            continue

        logger.info(f"Testing Model: '{model['name']}'.")

        generation_kwargs = {
            "max_tokens": 50,
            "echo": False,
            "temperature": 0.1,
            "top_k": 1
        }

        for prompt_data in prompts:
            logger.info(f"\tTesting Prompt: '{prompt_data['name']}'.")

            try:
                result = llm(prompt_data["prompt"], **generation_kwargs)
                output = get_first_line(result["choices"][0]["text"])
            except Exception as e:
                logger.error(f"Error generating result for prompt '{prompt_data['name']}': {e}")
                continue

            is_correct = clean_text(output) == clean_text(prompt_data['expected_answer'])

            result_dict = {
                "model": model['name'],
                "prompt_name": prompt_data['name'],
                "cat": prompt_data['cat'],
                "subcat": prompt_data['subcat'],
                "output": output,
                "expected_answer": prompt_data['expected_answer'],
                "expected_subject": prompt_data['expected_subject'],
                "expected_property": prompt_data['expected_property'],
                "expected_object": prompt_data['expected_object'],
                "is_correct": 1 if is_correct else 0
            }

            results.append(result_dict)

def test_openai_models(prompts, results):
    client = OpenAI()

    for prompt_data in prompts:
        try:
            completion = client.chat.completions.create(
                model="gpt-4o",
                messages=[{"role": "user", "content": prompt_data['prompt']}]
            )
            logger.info(f"Model response received successfully for prompt: {prompt_data['name']}")

            output = get_first_line(completion.choices[0].message.content)
            is_correct = clean_text(output) == clean_text(prompt_data['expected_answer'])

            result_dict = {
                "model": "gpt-4o",
                "prompt_name": prompt_data['name'],
                "cat": prompt_data['cat'],
                "subcat": prompt_data['subcat'],
                "output": output,
                "expected_answer": prompt_data['expected_answer'],
                "expected_subject": prompt_data['expected_subject'],
                "expected_property": prompt_data['expected_property'],
                "expected_object": prompt_data['expected_object'],
                "is_correct": 1 if is_correct else 0
            }

            results.append(result_dict)

        except Exception as e:
            logger.error(f"An unexpected error occurred for prompt '{prompt_data['name']}': {e}")



def main():
    prompts = load_prompts(PROMPTS_FILE)
    results = []

    # test_models(prompts, models, results)
    test_openai_models(prompts, results)
    save_results(results, RESULTS_FILE)

if __name__ == "__main__":
    main()

