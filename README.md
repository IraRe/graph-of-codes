# Graph of Codes - Data
Data for linking norms of german law with legal documents.

Data includes following sources:
1. Norms of german law downloaded from https://www.gesetze-im-internet.de/ and processed to a single CSV file - codes.csv and zpo.csv
2. Legal documents downloaded from https://openjur.de/ and processed to a single CSV file - document.csv
3. Extractions of norm occurrences in didactic material kindly provided by [Hanjo Hamann](https://www.coll.mpg.de/team/page/hanjo_hamann) - extracted_norms.csv

Cypher scripts for importing the data into the graph can be found in the scripts-folder. The script `codes_import.cql` has to be importet first.
