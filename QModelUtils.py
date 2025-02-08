import json
class QModelUtils:
    '''Utility class for QModelRDF.'''

    def convert_to_single_line(text):
        '''Simple util method to convert RDF-S prompt to a JSON compatible single line for dataset.'''
        return text.replace("\n", "\\n").replace("\"", "\\\"")

    def print_all_prompts_to_textfile(json_file_path, text_file_path):
        '''Method to print all prompts to a text file.'''
        # Read the JSON file
        with open(json_file_path, 'r') as json_file:
            prompts = json.load(json_file)
        
        # Write the prompts to the text file
        with open(text_file_path, 'w') as text_file:
            for prompt in prompts:
                text_file.write(prompt["prompt"])
                text_file.write(prompt["expected_answer"])
                text_file.write("\n\n")




input_text = """

"""

# QModelUtils.print_all_prompts_to_textfile("prompts.json", "prompts.txt")
# print(QModelUtils.convert_to_single_line(input_text))