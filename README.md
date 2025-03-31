
# Integrating-LLMs-and-Semantic-Web

## Overview

This project provides an automated testing pipeline for evaluating the performance of Large Language Models (LLMs) on tasks involving RDF-S (Resource Description Framework Schema) data. It assesses LLMs' abilities to understand RDF-S syntax, semantics, perform information retrieval, and make inferences. The pipeline supports both local quantized models (using llama.cpp) and OpenAI API models.

## Features

*   **Automated Testing:** Executes a predefined set of RDF-S based prompts against specified LLMs.
*   **Local and API Model Support:** Supports running quantized models locally using `llama.cpp` and interacting with OpenAI's GPT models via the API.
*   **Pass@k Evaluation:** Calculates the pass@k metric to account for the stochastic nature of LLMs.
*   **Modular Design:** The pipeline is designed to be modular, making it easy to add new models, prompts, and evaluation metrics.
*   **Comprehensive Reporting:** Generates JSON reports with detailed results for each model and prompt.
*   **Utility Functions:** Includes utility functions for formatting RDF-S prompts.
*   **Data Analysis with R:** Provides an R script (`analysis.R`) for analyzing the generated results and creating visualizations.

## Models being used

- hugging-quants/Llama-3.2-1B-Instruct-Q8_0-GGUF/llama-3.2-1b-instruct-q8_0.gguf  
- hugging-quants/Llama-3.2-3B-Instruct-Q8_0-GGUF/llama-3.2-3b-instruct-q8_0.gguf  
- thesus-research/llama-3.1-8b-prime-kg-exp-1-gguf/llama-3-1-8B-graph-128k.Q4_K_M.gguf  
- lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
- bartowski/phi-4-GGUF/phi-4-Q4_K_M.gguf
- Qwen/Qwen2.5-7B-Instruct-GGUF/qwen2.5-7b-instruct-q4_k_m-00001-of-00002.gguf
- MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF/Mistral-7B-Instruct-v0.3.Q4_K_M.gguf 
- bartowski/gemma-2-9b-it-GGUF/gemma-2-9b-it-Q4_K_M.gguf
- GPT-4o

## Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/jackfeighery/Integrating-LLMs-and-Semantic-Web.git
    cd Integrating-LLMs-and-Semantic-Web
    ```

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure Environment Variables:**
    Create a `.env` file in the root directory with the following variables:
    *   `MODEL_REP_PATH`: The absolute path to the directory containing your downloaded GGUF models.
    *   `OPENAI_API_KEY`: Your OpenAI API key (required for using GPT-4o).

    Example `.env` file:

    ```
    MODEL_REP_PATH=/path/to/your/models
    OPENAI_API_KEY=sk-your-openai-api-key
    ```

4.  **Download Quantized Models:**
    If you want to test local models, download the GGUF files for the models specified in the `models` list in `QModelRDF.py` and place them in the `MODEL_REP_PATH` directory. Make sure the paths specified in the `models` list match the actual filenames. Check in the python file, this has be explicitly stated already in "models variable"

## Usage

1.  **Run the Pipeline:**

    ```bash
    python QModelRDF.py
    ```

    This will:

    *   Load the prompts from `prompts.json`.
    *   Iterate through the models in the `models` list and test them against the prompts.
    *   Interact with the OpenAI API to test GPT-4o.
    *   Save the results to `pass10results.json`.

2.  **Analyze the Results:**

    An example `analysis.R` script is given to show how to compare the results and generate visualizations. Make sure R and the required packages are installed.

    ```R
    Rscript analysis.R
    ```

## Dataset (`prompts.json`)

The prompts used for testing are stored in `prompts.json`. Each prompt is a JSON object with the following fields:

*   `name`: Unique name of the prompt.
*   `prompt`: The RDF-S data and instruction to give to the LLM. The prompt requires this to work ""
*   `cat`: The category of the prompt (e.g., "Retrieval", "Inference").
*   `subcat`: The subcategory of the prompt (e.g., "Albums", "Chain1").
*   `expected_answer`: The correct answer to the prompt.
*   `expected_subject`: The correct subject of the expected answer (if applicable).
*   `expected_property`: The correct property of the expected answer (if applicable).
*   `expected_object`: The correct object of the expected answer (if applicable).
*   `description`: A short description of the prompt.

## Key Files

*   `QModelRDF.py`: The main script that runs the testing pipeline.
*   `QModelUtils.py`: Contains utility functions.
*   `prompts.json`: Contains the RDF-S based prompts.
*   `analysis.R`: R script for analyzing the results.
*   `requirements.txt`: Lists the Python dependencies.


## Open Day - Benchmark Browser Application

For the open day, a Flask web application was developed to browse all prompts in the benchmark dataset, view the RDF-S data of each prompt, and test the GPT-4o model on selected prompts. Users can browse through the prompts in the dataset using a simple interface. Upon clicking a prompt, details such as it's category, subcategory, instructions, expected answer, and a short description are shown. Users can test this prompt on the GPT-4o model, using a feature that sends the prompt to the OpenAI API and displays the results upon completion.