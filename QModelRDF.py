import os
from dotenv import load_dotenv
from pathlib import Path
import sys

# Redirect stderr to devnull to suppress verbose logging output
sys.stderr = open(os.devnull, 'w')

# Load environment variables from .env file
load_dotenv()

model_rep_path = Path(os.getenv("MODEL_REP_PATH"))

from llama_cpp import Llama

stops = []  # Define custom stop words here

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
        "name": "thesus-research/llama-3.1-8b-prime-kg-exp-1-gguf/llama-3-1-8B-graph-128k.Q4_K_M.gguf",
        "eos": stops + ['</s>']
    },
    # lmstudio-community
    # {
    #     "name": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
    #     "eos": stops + ['</s>']
    # }
]

# Loop through the models and load each one
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

    # Generation kwargs
    generation_kwargs = {
        "max_tokens": 2048,  # Max number of tokens to generate
        # "stop": model["eos"],  # End of sequence tokens to stop the generation process
        "echo": False,  # Echo the prompt in the output
        "temperature": 0.1,  # Temperature to be applied to the model
        "top_k": 1  # Top-k parameter to be applied to the model
    }

    # Run inference
    prompt = '''Below is an instruction that describes a task. Write a response that appropriately completes the request.
### Instruction:
Given the RDF data below:
@prefix ex: <http://example.org/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .

ex:Album2 a ex:MusicAlbum ;
    dc:title "Thriller" ;
    ex:artist ex:Artist2 ;
    ex:releaseYear "1982" ;
    ex:genre "Pop" ;
    ex:rating "5.0" .

ex:Artist2 a ex:Artist ;
    dc:name "Michael Jackson" ;
    ex:nationality "USA" ;
    ex:birthYear "1958" .

ex:Album4 a ex:MusicAlbum ;
    dc:title "Abbey Road" ;
    ex:artist ex:Artist4 ;
    ex:releaseYear "1969" ;
    ex:genre "Rock" ;
    ex:rating "4.9" .

ex:Artist4 a ex:Artist ;
    dc:name "The Beatles" ;
    ex:nationality "UK" ;
    ex:birthYear "1960" .

ex:Album3 a ex:MusicAlbum ;
    dc:title "Back in Black" ;
    ex:artist ex:Artist3 ;
    ex:releaseYear "1980" ;
    ex:genre "Rock" ;
    ex:rating "4.7" .

ex:Artist3 a ex:Artist ;
    dc:name "AC/DC" ;
    ex:nationality "Australia" ;
    ex:birthYear "1973" .

ex:Album1 a ex:MusicAlbum ;
    dc:title "Empire Burlesque" ;
    ex:artist ex:Artist1 ;
    ex:releaseYear "1985" ;
    ex:genre "Rock" ;
    ex:rating "4.5" .

ex:Artist1 a ex:Artist ;
    dc:name "Bob Dylan" ;
    ex:nationality "USA" ;
    ex:birthYear "1941" .

Which artist has the highest album rating?
Respond with a single RDF triple containing the artist concept.
Example of the expected response structure: ex:[artist concept] a ex:Artist.
### Response:
'''
    result = llm(prompt, **generation_kwargs)  # Result is a dictionary
    # Unpack and the generated text from the LLM response dictionary and print it
    print(result["choices"][0]["text"])


    '''
    JSON 
    name
    prompt 
    expected answer (S P O)
    expect subject: S
    expected property P
    expected oject: O
    '''
