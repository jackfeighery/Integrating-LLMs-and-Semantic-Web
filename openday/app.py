from flask import Flask, request, jsonify, render_template
import json
import os
from openai import OpenAI
import logging
from dotenv import load_dotenv
import re

load_dotenv()

app = Flask(__name__)
results = []

with open('prompts.json', 'r') as f:
    prompts = json.load(f)

@app.route('/')
def index():
    return render_template('index.html', prompts=prompts, title="Integrating Language Models and Semantic Web")

@app.route('/prompt/<string:prompt_name>',  methods=['GET', 'POST'])
def prompt(prompt_name):
    prompt = next((p for p in prompts if p["name"] == prompt_name), None)
    if prompt is None:
        return "Prompt not found", 404
    
    if request.method == 'POST':
        pass_k = int(request.form['pass_k'])
        results.clear()  # Clear previous results
        test_openai_models([prompt], results, pass_k=pass_k)

    return render_template('prompt.html', prompt=prompt, results=results, title=prompt["name"])

def clean_text(text):
    '''Function to clean the output and expected answer.'''
    text = re.split(r'\.', text, 1)[0]
    return re.sub(r'\s+', ' ', text).strip().lower()

def get_first_line(text):
    for line in text.split('\n'):
        if line.strip(): 
            return line
    return "" 

def test_openai_models(prompts, results, pass_k=10):
    client = OpenAI()

    for prompt_data in prompts:
        logging.info(f"\tTesting Prompt: '{prompt_data['name']}'.")
        correct_count, outputs = 0, []

        for _ in range(pass_k):
            try:
                completion = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": prompt_data['prompt']}]
                )
                logging.info(f"Model response received successfully for prompt: {prompt_data['name']}")

                output = get_first_line(completion.choices[0].message.content)
                outputs.append(output)
                if clean_text(output) == clean_text(prompt_data['expected_answer']):
                    correct_count += 1

            except Exception as e:
                logging.error(f"An unexpected error occurred for prompt '{prompt_data['name']}': {e}")

        result_dict = {
            "model": "gpt-4o",
            "prompt_name": prompt_data['name'],
            "cat": prompt_data['cat'],
            "subcat": prompt_data['subcat'],
            "outputs": outputs,
            "expected_answer": prompt_data['expected_answer'],
            "correct_count": correct_count
        }

        results.append(result_dict)

if __name__ == '__main__':
    app.run(debug=True)
