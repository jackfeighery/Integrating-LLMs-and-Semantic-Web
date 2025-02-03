import os
from dotenv import load_dotenv
from pathlib import Path
import logging
import json
import re

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

from openai import OpenAI

client = OpenAI()

try:
    with open('testprompts.json', 'r') as f:
        prompts = json.load(f)
except FileNotFoundError as e:
    logger.error(f"File not found: {e}")
    exit(1)
except json.JSONDecodeError as e:
    logger.error(f"Error decoding JSON: {e}")
    exit(1)

results_file = 'openai_results.json'
results = []

def get_first_line(text):
    for line in text.split('\n'):
        if line.strip(): 
            return line
    return "" 

def clean_text(text):
    '''Function to clean the output and expected answer.'''
    text = re.split(r'\.', text, 1)[0]
    return re.sub(r'\s+', ' ', text).strip().lower()



for prompt_data in prompts:    
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",  # [SC][TODO] for actual testing change the model to gpt-4o
            messages=[
                {
                    "role": "user",
                    "content": prompt_data['prompt']
                }
            ],
            # stop=["\n", "</s>"],
        )
        logger.info(f"Model response received successfully for prompt: {prompt_data['name']}")
        
        output = get_first_line(completion.choices[0].message.content)

        is_correct = clean_text(output) == clean_text(prompt_data['expected_answer'])
        
        result_dict = {
            "model": "gpt-4o",
            "prompt_name": prompt_data['name'],
            "expected_answer": prompt_data['expected_answer'],
            "expected_subject": prompt_data['expected_subject'],
            "expected_property": prompt_data['expected_property'],
            "expected_object": prompt_data['expected_object'],
            "is_correct": 1 if is_correct else 0
        }
        
        results.append(result_dict)
        
    except Exception as e:
        logger.error(f"An unexpected error occurred for prompt '{prompt_data['name']}': {e}")


try:
    with open(results_file, 'w') as file:
        json.dump(results, file, indent=4)
    logger.info(f"Results saved to '{results_file}'.")
except Exception as e:
    logger.error(f"Error saving results to '{results_file}': {e}")
