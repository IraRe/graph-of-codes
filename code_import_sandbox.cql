// create indexes for code properties
create index on :Code(codeTitle);
create index on :Code(forensicAbbreviation);


// import code nodes with names (forensic abbreviation and code title)
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_1.csv", {})
    yield map as line
    merge (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.info) > 0,
        "set c.codeTitle = line.info",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);
// import code nodes with names (forensic abbreviation and code title)
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_2.csv", {})
    yield map as line
    merge (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.info) > 0,
        "set c.codeTitle = line.info",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);


// import codes' footnotes
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_1.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.case([
            size(line.info) > 0 and exists(c.footnotes),
            "set c.footnotes = c.footnotes + line.footnote",
            size(line.info) > 0 and not exists(c.footnotes),
            "set c.footnotes = [line.footnote]"
        ],
        "", {c:c, line:line})
        yield value
    return count(*);
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_2.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.case([
            size(line.info) > 0 and exists(c.footnotes),
            "set c.footnotes = c.footnotes + line.footnote",
            size(line.info) > 0 and not exists(c.footnotes),
            "set c.footnotes = [line.footnote]"
        ],
        "", {c:c, line:line})
        yield value
    return count(*);


// create index for section's properties
create index on :Section(sectionNumber, sectionTitle);
create index on :Section(sectionNumber);
create index on :Section(sectionTitle);


// import sections of the codes with their number and title if existent
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_1.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.section) > 0,
        "merge (c)-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title})",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_2.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.section) > 0,
        "merge (c)-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title})",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);


// import paragraphs (heavy load operation)
call apoc.periodic.iterate(
    'call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_1.csv", {}) yield map as line',
    'match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title}) with line, s call apoc.do.when(size(line.paragraph) > 0, "create (s)-[:HAS_PARAGRAPH]->(p:Paragraph {text: line.paragraph})", "", {s:s, line:line}) yield value return count(*)',
    {batchSize:5000, parallel:true, iterateList:true});
call apoc.periodic.iterate(
    'call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_2.csv", {}) yield map as line',
    'match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title}) with line, s call apoc.do.when(size(line.paragraph) > 0, "create (s)-[:HAS_PARAGRAPH]->(p:Paragraph {text: line.paragraph})", "", {s:s, line:line}) yield value return count(*)',
    {batchSize:5000, parallel:true, iterateList:true});


create index on :Footnote(text);


// import paragraphs' footnotes
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_1.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    with line, c, s
    call apoc.do.when(
            size(line.footnote) > 0,
            "merge (s)-[:HAS_FOOTNOTE]->(:Footnote {text: line.footnote})",
            "",
            {s:s, line:line}
        )
        yield value
    return count(*);
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/codes_part_2.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    with line, c, s
    call apoc.do.when(
            size(line.footnote) > 0,
            "merge (s)-[:HAS_FOOTNOTE]->(:Footnote {text: line.footnote})",
            "",
            {s:s, line:line}
        )
        yield value
    return count(*);


// import ZPO (by repeating last load statements for zpo.csv)
call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv", {})
    yield map as line
    merge (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.info) > 0,
        "set c.codeTitle = line.info",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);

call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.case([
            size(line.info) > 0 and exists(c.footnotes),
            "set c.footnotes = c.footnotes + line.footnote",
            size(line.info) > 0 and not exists(c.footnotes),
            "set c.footnotes = [line.footnote]"
        ],
        "", {c:c, line:line})
        yield value
    return count(*);

call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})
    with c, line
    call apoc.do.when(
        size(line.section) > 0,
        "merge (c)-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title})",
        "",
        {c:c, line:line}
        )
        yield value
    return count(*);


call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section, sectionTitle: line.title})
    with line, s
    call apoc.do.when(
        size(line.paragraph) > 0,
        "create (s)-[:HAS_PARAGRAPH]->(p:Paragraph {text: line.paragraph})",
        "",
        {s:s, line:line}
        )
        yield value
    return count(*);


call apoc.load.csv("https://github.com/IraRe/graph-of-codes-data/raw/master/zpo.csv", {})
    yield map as line
    match (c:Code {forensicAbbreviation: line.code})-[:HAS_SECTION]->(s:Section {sectionNumber: line.section})
    with line, c, s
    call apoc.do.when(
            size(line.footnote) > 0,
            "merge (s)-[:HAS_FOOTNOTE]->(:Footnote {text: line.footnote})",
            "",
            {s:s, line:line}
        )
        yield value
    return count(*);


// extract paragraphs' numbers from the paragraphs' texts
match (p:Paragraph)
    set p.paragraphNumber = apoc.text.regexGroups(p.text, "\\((\\d+)\\)")[0][1];


// clean section number from suffixes like §, Art or Anlage
match (s:Section)
    where s.sectionNumber starts with '§ '
    set s.sectionNumber = substring(s.sectionNumber, 2)
    set s.sectionType = '§';


match (s:Section)
    where s.sectionNumber starts with 'Art '
    set s.sectionNumber = substring(s.sectionNumber, 4)
    set s.sectionType = 'Artikel';


match (s:Section)
    where s.sectionNumber starts with 'Anlage '
    set s.sectionNumber = substring(s.sectionNumber, 7)
    set s.sectionType = 'Anlage';


// rename codes with year number or version in their names
match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{4}'
    set c.releaseYear = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-4)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-4))
    return count(*);


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{3}'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-1)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-1))
    return count(*);


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d{2}'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-1)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-1))
    return count(*);


match (c:Code)
    where c.forensicAbbreviation =~ '\\w+\\s\\d'
    set c.version = substring(c.forensicAbbreviation, length(c.forensicAbbreviation)-1)
    set c.forensicAbbreviation = trim(substring(c.forensicAbbreviation, 0, length(c.forensicAbbreviation)-1))
    return count(*);


// connect codes with the same forensic abbreviation
// still difficult to distinguisch for example the LuftVODV Hamburg and LuftVODV FRA
match (c1:Code), (c2:Code)
    where c1.forensicAbbreviation = c2.forensicAbbreviation
        and id(c1) <> id(c2)
    merge (c1)-[:HAS_VARIATION]-(c2);
