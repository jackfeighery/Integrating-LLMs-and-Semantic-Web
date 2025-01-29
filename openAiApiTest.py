from dotenv import load_dotenv
from pathlib import Path

# load .env file that contains the OPENAI_API_KEY
load_dotenv()

from openai import OpenAI
client = OpenAI()


prompt = ''''
### You are a knowledge graph engineer. You only reply with RDF-S statements.
### Given the RDF-S data below, answer the following question "Which artist has the highest album rating?".
### Be succinct. Return a single line with one RDF-S triple surrounded by three backticks and containing the artist concept, for example: ```ex:Artis9 a ex:Artist.```
### Do not include any explanation or notes in your response.

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

### Response:
[REPLACE WITH YOUR RESPONSE]<|end_of_text|>
'''


completion = client.chat.completions.create(
    model="gpt-4o-mini", # [SC][TODO] for actual testing change the model to gpt-4o
    # messages=[
    #     {"role": "system", "content": "You are a RDF-S expert."},
    #     {
    #         "role": "user",
    #         "content": prompt
    #     }
    # ]
    messages=[
        {
            "role": "user",
            "content": prompt
        }
    ]
)


print(completion.choices[0].message)
print(completion.choices[0].message.content)