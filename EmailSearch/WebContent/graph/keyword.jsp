<%@ page import="java.util.*,java.util.regex.*" %>
<%@ page import="javax.mail.internet.*,javax.activation.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="javax.mail.*,javax.mail.search.SearchTerm"%>
<%@ page import="java.io.*"%>
<%@ page import="org.jsoup.*"%>
<%@ page import="org.apache.lucene.search.*,org.apache.lucene.misc.*,org.apache.lucene.sandbox.queries.*,org.apache.lucene.search.spans.*" %>
<%@ page import="org.apache.lucene.index.TermsEnum,org.apache.lucene.search.FuzzyTermsEnum,org.apache.lucene.queries.CommonTermsQuery" %>	
<%@ page import="org.apache.lucene.analysis.en.PorterStemFilter,org.apache.lucene.analysis.tokenattributes.*" %>
<%@ page import="org.apache.lucene.queryparser.classic.QueryParser,org.apache.lucene.search.highlight.*,org.apache.lucene.index.memory.*" %>
<%@ page import="org.apache.lucene.store.Directory,org.apache.lucene.store.FSDirectory,org.apache.lucene.index.*,org.apache.lucene.search.similarities.*" %>
<%@ page import="org.apache.lucene.store.*,org.apache.lucene.analysis.*,org.apache.lucene.analysis.standard.*,org.apache.lucene.document.*,org.apache.lucene.index.*,org.apache.lucene.index.IndexWriterConfig.*,org.apache.lucene.util.*" %>
<%@ page import="org.json.simple.JSONObject,org.json.simple.JSONValue,org.json.simple.parser.JSONParser,com.google.common.base.*" %>
<%@ page import="org.codehaus.jackson.*" %>
<%@ page import="com.google.common.collect.*"%>
<%@ page import="mx.bigdata.jcalais.*,mx.bigdata.jcalais.rest.*" %>
<%@ page import="stopwords.*,org.json.simple.*,javax.crypto.Cipher,javax.crypto.Cipher, org.apache.lucene.store.transform.algorithm.security.*, org.apache.lucene.store.transform.algorithm.compress.*,org.apache.lucene.store.transform.algorithm.*,org.apache.lucene.store.transform.*" %>
<%

CalaisClient client = new CalaisRestClient("gm6qms2bz2kxer6g39fyfvwv");
String input = request.getParameter("query");
String username = request.getParameter("name");

String rootPath ="/Users/chenhe/eclipse-workspace/EmailSearch/WebContent/graph/";
String indexPath = rootPath + "index/"+username;
int mailQuantity = 400;

long LastModified = (new File(indexPath+indexPath+"/_0.cfs")).lastModified() ;

List<String> clientquery = new ArrayList<String>(Arrays.asList(input.split("\\s+")));
LinkedHashSet<String> set = new LinkedHashSet<String>();
set.addAll(clientquery);
clientquery.clear();
clientquery.addAll(set);


Directory fsDirectory =  null;
IndexReader reader = null ;
/*try {
	fsDirectory = FSDirectory.open(new File(indexPath));
	reader = DirectoryReader.open(fsDirectory);
}
catch (Exception e)
{
	/// decrypt file first
	if((new File(indexPath+"/_0.cfs").exists()))
		(new File(indexPath+"/_0.cfs")).delete();
	String fileName=indexPath+"/_0.cfs";
	String encryptFileName=fileName+".enc";
	FileEncryptor.copy(Cipher.DECRYPT_MODE, encryptFileName, fileName, "!QAZ@WSX3edc4rfv"+MacAddress.Get());
	fsDirectory = FSDirectory.open(new File(indexPath));
	reader = DirectoryReader.open(fsDirectory);
}*/

/*Directory bdir = FSDirectory.open(new File(indexPath));
byte[] salt = new byte[16];
String encr_password = "lucenetransform"+MacAddress.Get();
DataEncryptor enc = new DataEncryptor("AES/ECB/PKCS5Padding", encr_password, salt, 128,false);
DataDecryptor dec = new DataDecryptor(encr_password, salt,false);

fsDirectory = new TransformedDirectory(bdir, enc, dec);
*/
fsDirectory = FSDirectory.open(new File(indexPath));
reader = DirectoryReader.open(fsDirectory);

IndexSearcher searcher = new IndexSearcher(reader);
Analyzer analyzer = new StandardAnalyzer(org.apache.lucene.util.Version.LUCENE_45);
SpanQuery[] spanquery = new SpanQuery[clientquery.size()];
for (int i=0; i<clientquery.size(); i++)
{
	PrefixQuery p = new PrefixQuery(new Term("content", clientquery.get(i).toLowerCase()));
	spanquery[i] = new SpanMultiTermQueryWrapper<PrefixQuery>(p);
}
SpanNearQuery q = new SpanNearQuery(spanquery,100000,false);

TopDocs topDocs = searcher.search(q,1000);
ScoreDoc[] hits = topDocs.scoreDocs;
int numTotalHits = topDocs.totalHits;

Integer[] msgid = new Integer[hits.length];
Integer[] date_array = new Integer[hits.length];

for (int i=0; i<hits.length;i++)
{
	Document doc = searcher.doc(hits[i].doc);
	msgid[i] = Integer.parseInt(doc.get("msgid"));
	date_array[i] = Integer.parseInt(doc.get("date"));
}

try {
	Arrays.sort(msgid);
	Arrays.sort(date_array);
	
	int biggestmsgid = msgid[msgid.length-1];
	int lessthanbiggestmsgid = msgid[0];
	if(msgid.length>mailQuantity) lessthanbiggestmsgid = msgid[msgid.length-mailQuantity];
	int smallestmsgid = msgid[0];
	int biggestdate = date_array[msgid.length-1];
	int smallestdate = date_array[0];
	
	Query q2 = NumericRangeQuery.newIntRange("msgid", lessthanbiggestmsgid, biggestmsgid,true,true);
	
	BooleanQuery query = new BooleanQuery();
	query.add(q,BooleanClause.Occur.MUST);
	query.add(q2,BooleanClause.Occur.MUST);
	
	topDocs = searcher.search(query,1000);
	hits = topDocs.scoreDocs;
	
	//out.println("Searching for: " + q.toString("subject")+"<br>");
	//out.println(hits.length + " total matching documents <br>");
	SimpleHTMLFormatter htmlFormatter = new SimpleHTMLFormatter();
	Highlighter highlighter = new Highlighter(htmlFormatter, new QueryScorer(q));
	
	
	Stopwords sw = new Stopwords();
	JazzySpellChecker SpellChecker = new JazzySpellChecker();
	DefaultSimilarity simi = new DefaultSimilarity();
	
	String content ="";
	int querylength = hits.length;
	//out.println(hits.length+"<br>");
	for (int i=0; i<hits.length;i++)
	{
		Document doc = searcher.doc(hits[i].doc);
		content=content+" to "+Jsoup.parse(doc.get("content")).text().replaceAll("<[^>]*>", "");
	}
	
	byte[] b = content.getBytes("UTF-8");
	content = new String(b, "ISO-8859-1");
	content = content.replaceAll("\\W"," ");
	
	
	ArrayList<String> GC = GetCollocations.GetCollocations(content);
	HashMap<String, Float> h = new HashMap<String, Float>();
	int j;
	for (j=0; j< GC.size(); j++)
	{
		float idf = simi.idf(Integer.parseInt(noOfDocsContainTerm(GC.get(j),username,searcher).get(0)), reader.numDocs());
		//out.println(GC.get(j)+": "+idf+"<br>");
		if(noOfDocsContainTerm(GC.get(j),username,searcher).get(1)!="null")
		{
			float tf = Float.parseFloat(noOfDocsContainTerm(GC.get(j),username,searcher).get(2));
			h.put(GC.get(j), idf*tf);
		}
	}
	List<Map.Entry<String, Float>> list = new ArrayList<Map.Entry<String, Float>>(h.entrySet());
	Collections.sort(list, new ValueThenKeyComparator<String, Float>());
	
	LinkedHashMap map = new LinkedHashMap();
	//for(int i=list.size()-1; i>=0; i--)
	//{
	for(int i=0; i<list.size(); i++)
	{
		//if(i<j-20) break;
		map.put(list.get(i).getKey(),list.get(i).getValue());
	}
	JSONArray jArray = new JSONArray();
	jArray.add(map);
	out.println(jArray);
	// count documents contains a term
	/* TermsEnum termEnum = MultiFields.getTerms(reader, "content").iterator(null);
	BytesRef bytesRef;
	while ((bytesRef = termEnum.next()) != null) {
	    int freq = reader.docFreq(new Term("content", bytesRef));
	
	    out.println(bytesRef.utf8ToString() + " in " + freq + " documents<br>");
	
	}*/
	}
catch (Exception ex)
{
	out.println("");
}
fsDirectory.close();
reader.close();

///delete decrypted file after use
/*if((new File(indexPath+"/_0.cfs").exists()))
{
	long CurrentLastModified = (new File(indexPath+indexPath+"/_0.cfs")).lastModified();
	if(CurrentLastModified==LastModified)
	{
		(new File(indexPath+"/_0.cfs")).delete();
	}
}*/

%>
<%!
public ArrayList<String> noOfDocsContainTerm(String querystr, String username,IndexSearcher searcher) throws CorruptIndexException, IOException, ParseException{

Analyzer analyzer = new StandardAnalyzer(org.apache.lucene.util.Version.LUCENE_45);

String[] clientquery = querystr.split("\\s+");
PhraseQuery query = new PhraseQuery();
query.setSlop(0);
for (int i=0; i<clientquery.length; i++)
{
	query.add(new Term("content", clientquery[i].toLowerCase()));
}
 
TopDocs topDocs = searcher.search(query,1000000);

ScoreDoc[] hits = topDocs.scoreDocs;
ArrayList<String> result = new ArrayList<String>();
result.add(0, Integer.toString(hits.length));
if(hits.length>0)
{
	Document doc = searcher.doc(hits[0].doc);
	result.add(1, doc.get("date"));
    Explanation explanation = searcher.explain(query, hits[0].doc);
    result.add(2, explanation.getDetails()[0].getDetails()[0].toString().split(" ")[0]);
}
else
	result.add(1, "null");


//fsDirectory.close();
//reader.close();
    return result;
}

%>


