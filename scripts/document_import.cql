create index on :Document(docketNumber);


// load documents with all relevant properties
load csv with headers from "https://github.com/IraRe/graph-of-codes-data/raw/master/document.csv" as line
    merge (doc:Document {docketNumber: line.aktenzeichen})
        set doc.court = line.gericht
        set doc.date = line.datum
        set doc.documentType = line.dokumenttyp
        set doc.citation = line.fundstelle
        set doc.permalink = line.permalink
        set doc.operativePart = line.tenor
        set doc.legalReasons = line.gruende
        set doc.legalNorms = split(line.normen, ",")
        set doc.legalFields = split(line.rechtsgebiete, ",")
        set doc.principles = line.leitsaetze
        set doc.followingCourt = line.nachinstanz
        set doc.previousCourt = line.vorinstanz
        set doc.statementOfFacts = line.tatbestand
        set doc.occurrencesInReasons = split(replace(replace(line.occurrences_reasons,"[ {",""),"} ]",""),"}, {")
        set doc.occurrencesInOperativePart = split(replace(replace(line.occurrences_tenor,"[ {",""),"} ]",""),"}, {")
        set doc.occurrencesInPrinciples = split(replace(replace(line.occurrences_principles,"[ {",""),"} ]",""),"}, {")
        set doc.occurrencesInFacts = split(replace(replace(line.occurrences_facts,"[ {",""),"} ]",""),"}, {");


// create courts and link them with documents
create index on :Court(courtName);


match (d:Document) where exists(d.court)
    merge (c:Court {courtName:trim(d.court)})
    merge (d)-[:CREATED_AT]->(c)
    remove d.court;


// create legal field nodes and link them with documents
create index on :LegalField(legalFieldName);


match (d:Document) where exists(d.legalFields)
    foreach (l in d.legalFields |
        merge (lf:LegalField {legalFieldName:trim(l)})
        merge (d)-[:DEALS_WITH]->(lf))
    remove d.legalFields;


// add document type label
match (d:Document) where d.documentType = 'Beschluss'
    set d:Order
    remove d.documentType;


match (d:Document) where d.documentType = 'Urteil'
    set d:Verdict
    remove d.documentType;


match (d:Document) where d.documentType = 'Verfügung'
    set d:Decision
    remove d.documentType;


match (d:Document) where d.documentType = 'Teil-Urteil'
    set d:PartJudgment
    remove d.documentType;


// create and link norm occurrences in documents
match (d:Document) where exists(d.occurrencesInReasons)
    foreach (occ in d.occurrencesInReasons |
        create (o:Occurrence)
        set o.props = split(trim(occ),',')
        set o.occurredIn = 'legal reasons'
        create (d)-[:HAS_OCCURRENCE]->(o))
    remove d.occurrencesInReasons;


match (d:Document) where exists(d.occurrencesInFacts)
    foreach (occ in d.occurrencesInFacts |
        create (o:Occurrence)
        set o.props = split(trim(occ),',')
        set o.occurredIn = 'statement of facts'
        create (d)-[:HAS_OCCURRENCE]->(o))
    remove d.occurrencesInFacts;


match (d:Document) where exists(d.occurrencesInPrinciples)
    foreach (occ in d.occurrencesInPrinciples |
        create (o:Occurrence)
        set o.props = split(trim(occ),',')
        set o.occurredIn = 'principles'
        create (d)-[:HAS_OCCURRENCE]->(o))
    remove d.occurrencesInPrinciples;


match (d:Document) where exists(d.occurrencesInOperativePart)
    foreach (occ in d.occurrencesInOperativePart |
        create (o:Occurrence)
        set o.props = split(trim(occ),',')
        set o.occurredIn = 'operative part'
        create (d)-[:HAS_OCCURRENCE]->(o))
    remove d.occurrencesInOperativePart;


// delete empty occurrences
match (o:Occurrence)
    where '[ Empty or null ]' in o.props
    detach delete o;


match (o:Occurrence)
    where o.props = ["[ ]"]
    detach delete o;


// connect documents with code paragraphs and sections
match (d:Document) where exists(d.legalNorms)
    unwind d.legalNorms as norm
    with apoc.text.regexGroups(norm,"(§|Art\\.)\\s(?<section>[\\da-z]+)(\\sAbs\\.\\s(?<paragraph>[\\da-z]+))?(\\sSatz\\s(?<sentence>[\\da-z]+))?\\s(?<code>\\w+)") as groups, d, norm
    call apoc.do.when(groups[0][4] is null,
        "match (c:Code {forensicAbbreviation:code})-[:HAS_SECTION]->(s:Section {sectionNumber:section}) merge (d)-[:MAKES_USE_OF {fullNormCitation:norm}]->(s)",
        "match (c:Code {forensicAbbreviation:code})-[:HAS_SECTION]->(s:Section {sectionNumber:section})-[:HAS_PARAGRAPH]->(p:Paragraph {paragraphNumber:paragraph}) merge (d)-[:MAKES_USE_OF {fullNormCitation:norm}]->(p)",
        {section:groups[0][2], paragraph:groups[0][4], code:groups[0][7], norm:norm, d:d})
        yield value
    return count(*);


match (c:Code)
    where c.forensicAbbreviation = 'GVGEG'
    set c.alternativeForensicAbbreviation = 'EGGVG'
    return c;


match (d:Document) where exists(d.legalNorms)
    unwind d.legalNorms as norm
    with apoc.text.regexGroups(norm,"(§|Art\\.)\\s(?<section>[\\da-z]+)(\\sAbs\\.\\s(?<paragraph>[\\da-z]+))?(\\sSatz\\s(?<sentence>[\\da-z]+))?\\s(?<code>\\w+)") as groups, d, norm
    call apoc.do.when(groups[0][4] is null,
        "match (c:Code {alternativeForensicAbbreviation:code})-[:HAS_SECTION]->(s:Section {sectionNumber:section}) merge (d)-[:MAKES_USE_OF {fullNormCitation:norm}]->(s)",
        "match (c:Code {alternativeForensicAbbreviation:code})-[:HAS_SECTION]->(s:Section {sectionNumber:section})-[:HAS_PARAGRAPH]->(p:Paragraph {paragraphNumber:paragraph}) merge (d)-[:MAKES_USE_OF {fullNormCitation:norm}]->(p)",
        {section:groups[0][2], paragraph:groups[0][4], code:groups[0][7], norm:norm, d:d})
        yield value
    return count(*);


// remove legalNorms property
match (d:Document)-[:MAKES_USE_OF]->()
    where exists(d.legalNorms)
    remove d.legalNorms;


// split properties of Occurence nodes in order to connect them with
// code sections and norms in next steps
match (o:Occurrence) where exists(o.props)
    unwind o.props as prop
    with o, trim(split(prop,':')[0]) as key, trim(split(prop,':')[1]) as value
    set o +=  apoc.map.fromValues([key, value]);


match (o:Occurrence) where exists(o.props) remove o.props;


//connect occurences with norm paragraphs and sections
match (o:Occurrence) where exists(o.code)
    call apoc.do.case([
        exists(o.section) and exists(o.paragraph),
        'match (c:Code)-[:HAS_SECTION]->(s:Section {sectionNumber:o.section})-[:HAS_PARAGRAPH]->(p:Paragraph {paragraphNumber:o.paragraph}) where c.forensicAbbreviation = o.code or c.alternativeForensicAbbreviation = o.code create (p)-[:OCCURS_IN]->(o)<-[:OCCURS_IN]-(s)',
        exists(o.section),
        'match (c:Code)-[:HAS_SECTION]->(s:Section {sectionNumber:o.section}) where c.forensicAbbreviation = o.code or c.alternativeForensicAbbreviation = o.code create (o)<-[:OCCURS_IN]-(s)'
        ],
        '', {o:o}) yield value
        return value;
