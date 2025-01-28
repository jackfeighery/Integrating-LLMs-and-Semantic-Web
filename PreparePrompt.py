

def convert_to_single_line(text):
    '''Simple util method to convert RDF-S prompt to a JSON compatible single line for dataset.'''
    return text.replace("\n", "\\n").replace("\"", "\\\"")

input_text = """
Below is an instruction that describes a task. Write a response that appropriately completes the request.
### Instruction:
Given the RDF data below:

ex:Cat rdfs:subClassOf ex:Mammal.
ex:Canis rdfs:subClassOf ex:Mammal.
ex:Tiger rdfs:subClassOf ex:Cat.
ex:Tigris rdfs:subClassOf ex:Tiger.

Can it be inferred that "ex:Tigris rdfs:subClassOf ex:Tiger"?
Respond with a single word, either Yes or No.
Example response: Yes.
Example response: No.
### Response:
"""

print(convert_to_single_line(input_text))