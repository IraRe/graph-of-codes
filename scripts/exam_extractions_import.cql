load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/extracted_norms.csv" as line
merge (doc:Document:Exam {exam: line.exam})
create (occ:Occurrence {at: line.ID})
    set occ.code = line.code
    set occ.section = line.par
    set occ.paragraph = line.abs
    set occ.fullOccurrence = line.section
merge (doc)-[:HAS_OCCURRENCE]->(occ);

match (o:Occurrence) where exists(o.code)
    call apoc.do.case([
        exists(o.section) and exists(o.paragraph),
        'match (c:Code)-[:HAS_SECTION]->(s:Section {sectionNumber:o.section})-[:HAS_PARAGRAPH]->(p:Paragraph {paragraphNumber:o.paragraph}) where c.forensicAbbreviation = o.code or c.alternativeForensicAbbrivation = o.code merge (p)-[:OCCURS_IN]->(o)<-[:OCCURS_IN]-(s)',
        exists(o.section),
        'match (c:Code)-[:HAS_SECTION]->(s:Section {sectionNumber:o.section}) where c.forensicAbbreviation = o.code or c.alternativeForensicAbbrivation = o.code merge (o)<-[:OCCURS_IN]-(s)'
        ],
        '', {o:o}) yield value
        return value;
