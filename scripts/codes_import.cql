// create indexes for code properties
create index on :Code(codeTitle);
create index on :Code(forensicAbbreviation);


// import code nodes with names (forensic abbreviation and code title)
using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/codes.csv" as line
    merge (c:Code {forensicAbbreviation: line.code})
    with * where size(line.info) > 0
    set c.codeTitle = line.info;


// import codes' footnotes
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/codes.csv" as line
    with * where size(line.info) > 0
    match (c:Code {forensicAbbreviation: line.code})
    set c.footnotes = coalesce(c.footnotes,[]) + line.footnote;


// create index for section's properties
create index on :Section(sectionNumber, sectionTitle);
create index on :Section(sectionNumber);
create index on :Section(sectionTitle);


// import sections of the codes with their number and title if existent
using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/codes.csv" as line
    with * where size(line.section) > 0
    match (c:Code {forensicAbbreviation: line.code})
    merge (c)-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    on create set s.sectionTitle = line.title;


// import paragraphs (heavy load operation)
using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/codes.csv" as line
    with * where size(line.paragraph) > 0
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title})
    create (s)-[:HAS_PARAGRAPH]->(p:Paragraph {text: line.paragraph});


create index on :Footnote(text);

// import paragraphs' footnotes
using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/codes.csv" as line
    with * where size(line.footnote) > 0
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    merge (s)-[:HAS_FOOTNOTE]->(:Footnote {text: line.footnote});


// import ZPO (by repeating last load statements for zpo.csv)
using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv" as line
    with * where size(line.info) > 0
    merge (c:Code {forensicAbbreviation: line.code})
    set c.codeTitle = line.info;

using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv" as line
    with * where size(line.footnote) > 0
    match (c:Code {forensicAbbreviation: line.code})
    set c.footnotes = coalesce(c.footnotes,[]) + [line.footnote];

using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv" as line
    with * where size(line.section) > 0
    match (c:Code {forensicAbbreviation: line.code})
    merge (c)-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    on create set s.sectionTitle=line.title;


using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv" as line
    with * where size(line.paragraph) > 0
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    create (s)-[:HAS_PARAGRAPH]->(p:Paragraph {text: line.paragraph});


using periodic commit 500
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv" as line
    with * where size(line.footnote) > 0
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    merge (s)-[:HAS_FOOTNOTE]->(:Footnote {text: line.footnote});


// extract paragraphs' numbers from the paragraphs' texts
call apoc.periodic.iterate(
        'cypher runtime=slotted match (p:Paragraph) return p',
        'set p.paragraphNumber = apoc.text.regexGroups(p.text, "\\\\((\\\\d+)\\\\)")[0][1]',
        {batchSize:10000, iterateList:true}
    );


// clean section number from suffixes like §, Art or Anlage
call apoc.periodic.iterate(
        "match (s:Section) where s.sectionNumber starts with '§ ' return s",
        "set s.sectionNumber = substring(s.sectionNumber, 2) set s.sectionType = '§' set s:SParagraph",
        {batchSize:10000, iterateList:true}
    );


call apoc.periodic.iterate(
        "match (s:Section) where s.sectionNumber starts with 'Art ' return s",
        "set s.sectionNumber = substring(s.sectionNumber, 4) set s.sectionType = 'Artikel' set s:SArticle",
        {batchSize:10000, iterateList:true}
    );



call apoc.periodic.iterate(
        "match (s:Section) where s.sectionNumber starts with 'Anlage ' return s",
        "set s.sectionNumber = substring(s.sectionNumber, 7) set s.sectionType = 'Anlage' set s:SRider",
        {batchSize:10000, iterateList:true}
    );

// rename codes with year number or version in their names
match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{4}'
    set c.releaseYear = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-4)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-4));


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{3}'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-3)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-3));


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{2}'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-2)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-2));


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-1)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-1));


// connect codes with the same forensic abbreviation
// still difficult to distinguisch for example the LuftVODV Hamburg and LuftVODV FRA
match (c1:Code), (c2:Code)
    where c1.forensicAbbreviation = c2.forensicAbbreviation and id(c1) > id(c2)
    merge (c1)-[:HAS_VARIATION]-(c2);
