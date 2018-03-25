# Connected Law

## Introduction

### Data Sources

As a part of my preparation for a [conference talk](https://programm.javaland.eu/2018/#/scheduledEvent/549166) I have imported and connected in a graph following data:
1. Norms of German law provided by "Bundesministerium der Justiz und für Verbraucherschutz" and "juris GmbH" under [https://www.gesetze-im-internet.de/](https://www.gesetze-im-internet.de/)
2. Legal documents provided by open [openJur e.V.](https://openjur.de/)
3. Extractions of norm occurrences in didactic material kindly provided by [Hanjo Hamann](http://hanjo.1hamann.de/)

### Data Processing

#### Transforming to CSV files

For more convenient import of the data into the graph I have processed all the sources with a [KNIME](https://www.knime.com/) workflow into a CSV file suitable for my purposes.* All the transformed data can be found on this [GitHub repository](https://github.com/IraRe/graph-of-codes-data).

For the extraction of norm occurrences in legal documents following regular expression was used:
```
(§|§§|Art\.?)(?<codes>,?\s(?<section>[\da-c]+)(\sI{0,3}V?)?((\sund\s(?<section2>[\da-c]+))|(?<sections>(,\s?[\da-c]+(\sI)?)+)|-(?<toSection>\d+))?((\s(Abs\.|Absatz)\s?(?<paragraph>\d)+(\sund\s(?<paragraph2>\d+))?)?(?<paragraphs>,\s\d+)*(\s(S\.|Satz)\s?(?<sentence>\d+),?)?)+(\sNr\.\s(?<number>\d+))?(\sff\.)?(\s(?<subsentence>\d+)\.\sHalbsatz)?(\s(?<alternative>\d+)\.\sAlt\.)?)+(\sdes)?\s(?<code>[^Rn]\w+(\s[VIX]+)?)(,\s(?<c2Section>\d+)\sAbs\.\s(?<c2Paragraph>\d+)\s(?<c2Code>\w+))?
```

#### Importing into the graph

Cypher scripts used for importing the data into the Neo4j database can be also found on a [GitHub repository](here: https://github.com/IraRe/graph-of-codes-data/tree/master/scripts).
In order to properly import and connect the data, please start the import with the `codes_import.cql` script.

## Exploring data in the graph

A Neo4j Sandbox instance with all the data already imported will be available until the end of April under the following IP address: 
```
http://107.23.190.94:33961/browser/
```
The user `codes` with the same password has a reading access to the data.

For exploring the linked data in the graph I have created two browser guides:
1. The original German guide used at JavaLand can be run via 
```
:play https://guides.neo4j.com/javaland.html
```
2. A more enhanced English version will be added soon.


A persistent deployment on https://neo4j.com/cloud/ will be created soon. 

## *Disclaimer
As a result of trial and error processing of the data, this project doesn't satisfy the requirements of [reproducible research](https://www.coursera.org/learn/reproducible-research). 

A bulk of XML files with German law norms was extracted by Hanjo Hamann as of the middle of 2017 from https://www.gesetze-im-internet.de/. The legal documents imported into the graph were downloaded by me randomly (all the docket numbers are persisted in the graph though) from https://openjur.de/. The full texts of the didactic material, as well as the regular expression used for extracting of the norm occurrences of the third data source, are not available to me. The KNIME workflows used for transformation of those files to CSVs can be substituted by any other script using the same regular expression for norm occurrences extractions as listed above.

The dataset provided as a graph is aimed to show how data analysis of legal texts can be undertaken by means of graph theory. For a complete and broad project in this area, more attempt for reproducible and continuous data delivery into the graph has to be made.
