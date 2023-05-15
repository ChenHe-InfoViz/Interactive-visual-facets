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
<%@ page import="org.json.simple.JSONObject,org.json.simple.JSONValue,com.google.common.base.*" %>
<%@ page import="org.codehaus.jackson.*" %>
<%@ page import="com.google.common.collect.*"%>
<%@ page import="mx.bigdata.jcalais.*,mx.bigdata.jcalais.rest.*" %>
<%@ page import="stopwords.*,org.json.simple.*, javax.crypto.Cipher,javax.crypto.Cipher, org.apache.lucene.store.transform.algorithm.security.*, org.apache.lucene.store.transform.algorithm.compress.*,org.apache.lucene.store.transform.algorithm.*,org.apache.lucene.store.transform.*" %>
<%
CalaisClient client = new CalaisRestClient("gm6qms2bz2kxer6g39fyfvwv");
String input = "";
String username = request.getParameter("name");
List<String> clientquery = new ArrayList<String>(Arrays.asList(input.split("\\s+")));
LinkedHashSet<String> set = new LinkedHashSet<String>();
set.addAll(clientquery);
clientquery.clear();
clientquery.addAll(set);

String rootPath = "/Users/chenhe/eclipse-workspace/EmailSearch/WebContent/graph/";
String indexPath = rootPath + "index/"+username;
int mailQuantity = 400;

/// decrypt file first
/*if((new File(indexPath+"/_0.cfs").exists()))
	(new File(indexPath+"/_0.cfs")).delete();
String fileName=indexPath+"/_0.cfs";
String encryptFileName=fileName+".enc";
FileEncryptor.copy(Cipher.DECRYPT_MODE, encryptFileName, fileName, "!QAZ@WSX3edc4rfv"+MacAddress.Get());
*/

/*Directory bdir = FSDirectory.open(new File(indexPath));
byte[] salt = new byte[16];
String encr_password = "lucenetransform"+MacAddress.Get();
DataEncryptor enc = new DataEncryptor("AES/ECB/PKCS5Padding", encr_password, salt, 128,false);
DataDecryptor dec = new DataDecryptor(encr_password, salt,false);

Directory fsDirectory = new TransformedDirectory(bdir, enc, dec);
*/
Directory fsDirectory =  FSDirectory.open(new File(indexPath));
IndexReader reader = DirectoryReader.open(fsDirectory);
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
LinkedHashMap<String,LinkedHashMap<String,String>> list = new LinkedHashMap<String,LinkedHashMap<String,String>>();
float denominator = hits[0].score;

Integer[] msgid = new Integer[hits.length];
Integer[] date_array = new Integer[hits.length];

for (int i=0; i<hits.length;i++)
{
	Document doc = searcher.doc(hits[i].doc);
	msgid[i] = Integer.parseInt(doc.get("msgid"));
	date_array[i] = Integer.parseInt(doc.get("date"));
}

try{
	Arrays.sort(msgid);
	Arrays.sort(date_array);
	
	int biggestmsgid = msgid[msgid.length-1];
	int smallestmsgid = msgid[0];
	int biggestdate = date_array[msgid.length-1];
	int smallestdate = date_array[0];
	
	Query new_q = NumericRangeQuery.newIntRange("msgid", biggestmsgid-(mailQuantity-2), biggestmsgid,true,true);
	
	topDocs = searcher.search(new_q,1000);
	hits = topDocs.scoreDocs;
	
	for (int i=0; i<hits.length;i++)
	{
	
		Document doc = searcher.doc(hits[i].doc);
		TokenStream tokenStream = TokenSources.getAnyTokenStream(searcher.getIndexReader(), hits[i].doc, "content", analyzer);
	    LinkedHashMap<String,String> dataMap = new LinkedHashMap<String,String>();
	    String temp =  doc.get("date").toString();
		String date = NumberToMonth(temp.substring(4, 6))+" "+temp.substring(6, 8)+" "+temp.substring(0, 4);
		dataMap.put("date",date);
		dataMap.put("subject", doc.get("subject"));
	    dataMap.put("content", doc.get("content").replaceAll("<[^>]*>", "").replaceAll("\r", "").replaceAll("&nbsp;"," ").replaceAll(" +", " ").replaceAll("(\\s*\n)\\1+", "\n").replaceAll("(\\s*\n)\\1+", "\n").replaceAll(">", ""));
	    dataMap.put("relevance", Float.toString(hits[i].score/denominator));
	    dataMap.put("from", doc.get("from"));
	    dataMap.put("to", doc.get("to"));
	    dataMap.put("attachment", doc.get("attachment")+"");
	    dataMap.put("biggestmsgid", biggestmsgid+"");
	    dataMap.put("smallestmsgid", smallestmsgid+"");
	    dataMap.put("biggestdate", biggestdate+"");
	    dataMap.put("smallestdate", smallestdate+"");
		list.put(doc.get("msgid"), dataMap);
	}
	JSONArray jArray = new JSONArray();
	jArray.add(list);
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
public ArrayList<String> noOfDocsContainTerm(String querystr,String username) throws CorruptIndexException, IOException, ParseException{

String indexPath ="/Users/chenhe/eclipse-workspace/EmailSearch/WebContent/graph/index/"+username;
Directory fsDirectory =  FSDirectory.open(new File(indexPath));
IndexReader reader = DirectoryReader.open(fsDirectory);
IndexSearcher searcher = new IndexSearcher(reader);
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
}
else
	result.add(1, "null");


fsDirectory.close();
reader.close();
    return result;
}



public String NumberToMonth(String value)
{
	
	String result;
	Integer month = Integer.parseInt(value);
	switch (month){
	case 1:
		result = "Jan";
		break;
	case 2:
		result = "Feb";
		break;
	case 3:
		result = "Mar";
		break;
	case 4:
		result = "Apr";
		break;
	case 5:
		result = "May";
		break;
	case 6:
		result = "Jun";
		break;
	case 7:
		result = "Jul";
		break;
	case 8:
		result = "Aug";
		break;
	case 9:
		result = "Sep";
		break;
	case 10:
		result = "Oct";
		break;
	case 11:
		result = "Nov";
		break;
	case 12:
		result = "Dec";
		break;
	default:
		result = "00";
	}
	return result;
}

%>


