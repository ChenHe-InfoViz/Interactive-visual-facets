<%@ page import="java.util.*,java.util.regex.*" %>
<%@ page import="javax.mail.internet.*,javax.activation.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="javax.mail.*,javax.mail.search.SearchTerm"%>
<%@ page import="java.io.*"%>
<%@ page import="org.jsoup.*"%>
<%@ page import="org.apache.lucene.search.*,org.apache.lucene.misc.*,org.apache.lucene.sandbox.queries.*,org.apache.lucene.search.spans.*" %>
<%@ page import="org.apache.lucene.index.TermsEnum,org.apache.lucene.search.FuzzyTermsEnum,org.apache.lucene.queries.CommonTermsQuery,org.apache.lucene.search.NumericRangeQuery.*" %>	
<%@ page import="org.apache.lucene.analysis.en.PorterStemFilter,org.apache.lucene.analysis.tokenattributes.*" %>
<%@ page import="org.apache.lucene.queryparser.classic.QueryParser,org.apache.lucene.search.highlight.*,org.apache.lucene.index.memory.*" %>
<%@ page import="org.apache.lucene.store.Directory,org.apache.lucene.store.FSDirectory,org.apache.lucene.index.*,org.apache.lucene.search.similarities.*" %>
<%@ page import="org.apache.lucene.store.*,org.apache.lucene.analysis.*,org.apache.lucene.analysis.standard.*,org.apache.lucene.document.*,org.apache.lucene.index.*,org.apache.lucene.index.IndexWriterConfig.*,org.apache.lucene.util.*" %>
<%@ page import="org.json.simple.JSONObject,org.json.simple.JSONValue,org.json.simple.parser.JSONParser,com.google.common.base.*" %>
<%@ page import="org.codehaus.jackson.*" %>
<%@ page import="com.google.common.collect.*"%>
<%@ page import="mx.bigdata.jcalais.*,mx.bigdata.jcalais.rest.*" %>
<%@ page import="stopwords.*,org.json.simple.*,javax.crypto.Cipher, org.apache.lucene.store.transform.algorithm.security.*, org.apache.lucene.store.transform.algorithm.compress.*,org.apache.lucene.store.transform.algorithm.*,org.apache.lucene.store.transform.*" %>
<%
CalaisClient client = new CalaisRestClient("gm6qms2bz2kxer6g39fyfvwv");
String input = "";
String username = request.getParameter("name");
List<String> clientquery = new ArrayList<String>(Arrays.asList(input.split("\\s+")));
LinkedHashSet<String> set = new LinkedHashSet<String>();
set.addAll(clientquery);
clientquery.clear();
clientquery.addAll(set);


//String indexPath ="index/"+username;
//String indexPath =getServletContext().getRealPath("/index/"+username);

String rootPath ="/Users/chenhe/eclipse-workspace/EmailSearch/WebContent/graph/";
String indexPath = rootPath + "index/"+username;
int mailQuantity = 400;

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
SimpleHTMLFormatter htmlFormatter = new SimpleHTMLFormatter();
Highlighter highlighter = new Highlighter(htmlFormatter, new QueryScorer(q));

String content ="";
float denominator = hits[0].score;

Integer[] msgid = new Integer[hits.length];

for (int i=0; i<hits.length;i++)
{
	Document doc = searcher.doc(hits[i].doc);
	msgid[i] = Integer.parseInt(doc.get("msgid"));
}

try{
	Arrays.sort(msgid);
	
	int biggestmsgid = msgid[msgid.length-1];
	int smallestmsgid = msgid[0];
	Query new_q = NumericRangeQuery.newIntRange("msgid", biggestmsgid-mailQuantity+2, biggestmsgid,true,true);
	
	topDocs = searcher.search(new_q,1000);
	hits = topDocs.scoreDocs;
	Stopwords sw = new Stopwords();
	JazzySpellChecker SpellChecker = new JazzySpellChecker();
	DefaultSimilarity simi = new DefaultSimilarity();
	
	String from ="";
	ArrayList<String> people = new ArrayList<String>();
	int index=0;
	HashMap<String, Float> h = new HashMap<String, Float>();
	
	for (int i=0; i<hits.length;i++)
	{
	
		Document doc = searcher.doc(hits[i].doc);
		from=doc.get("from").toLowerCase();
		if(!people.contains(from)&&!from.equals(username))
		{
			people.add(index, from);
			float idf = simi.idf(Integer.parseInt(noOfDocsContainTerm(from,username,searcher).get(0)), reader.numDocs());
			h.put(from, idf);
		}
		String[] to = doc.get("to").toLowerCase().split("~");
		for (int p=0; p<to.length;p++)
		{
			String person = to[p];
			if(!people.contains(person)&&!person.trim().isEmpty()&&!person.equals(username))
			{
				people.add(index, person);
				float idf = simi.idf(Integer.parseInt(noOfDocsContainTerm(person,username,searcher).get(0)), reader.numDocs());
				h.put(person, idf);
			}
		}
	}
	List<Map.Entry<String, Float>> list = new ArrayList<Map.Entry<String, Float>>(h.entrySet());
	Collections.sort(list, new ValueThenKeyComparator<String, Float>());
	
	LinkedHashMap map = new LinkedHashMap();
	for(int i=0; i<list.size(); i++)
	{
		map.put(list.get(i).getKey(),list.get(i).getValue());
	}
	JSONArray jArray = new JSONArray();
	jArray.add(map);
	out.println(jArray);
}
catch(Exception e)
{ 
	out.println("");
}
fsDirectory.close();
reader.close();
%>
<%!
public ArrayList<String> noOfDocsContainTerm(String querystr, String username, IndexSearcher searcher) throws CorruptIndexException, IOException, ParseException{

//IndexReader reader = DirectoryReader.open(fsDirectory);
//IndexSearcher searcher = new IndexSearcher(reader);
Analyzer analyzer = new StandardAnalyzer(org.apache.lucene.util.Version.LUCENE_45);

String[] clientquery = querystr.split("\\s+");
PhraseQuery query = new PhraseQuery();
query.setSlop(0);
for (int i=0; i<clientquery.length; i++)
{
	//System.out.println(clientquery[i].toLowerCase());
	query.add(new Term("from", clientquery[i].toLowerCase()));
}
 
TopDocs topDocs = searcher.search(query,1000000);

ScoreDoc[] hits = topDocs.scoreDocs;
ArrayList<String> result = new ArrayList<String>();
result.add(0, Integer.toString(hits.length));
//System.out.println(hits.length);
if(hits.length>0)
{
	Document doc = searcher.doc(hits[0].doc);
	result.add(1, doc.get("date"));
}
else
	result.add(1, "null");


//fsDirectory.close();
//reader.close();
    return result;
}

%>


