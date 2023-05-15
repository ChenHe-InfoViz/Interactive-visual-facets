<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Insert title here</title>
</head>
<body>
<%@ page import="mx.bigdata.jcalais.*,mx.bigdata.jcalais.rest.*" %>
<%@ page import="java.util.*" %>
<%@ page import="org.codehaus.jackson.*" %>
<%@ page import="com.google.common.collect.*"%>
<%

CalaisClient client = new CalaisRestClient("gm6qms2bz2kxer6g39fyfvwv");

CalaisResponse res = client.analyze("Reason for not attending tomorrow's seminar. meeting for thesis advice. Support setting up web server Dear Päivi" 
		+"Tung Vuong is doing a thesis in email search, Email Information Retrieval, Visualization with me in the hiit wide focus area. I will soon also make a contract for him but would need nbow access as HIIT accounts to start the work. "
		+"Could you add him and notify it-accounts@hiit.fi that he can have accounts and access? "
		+" Recent news and upcoming events at the Department - For students. Thanks "
		+" Giulio Jacucci "
		+" . Helsinki Institute for Information Technology HIIT " 
		+" Department of Computer Science" 
		+" P.O. Box 68 (Gustaf Hällströmin katu 2b) "
		+" FI-00014 UNIVERSITY OF HELSINKI "
		+" giulio.jacucci@helsinki.fi "
		+" 358  9 191 51153");


//CalaisResponse res = client.analyze("A big challenge companies face today is that most information, both online and archived, is only available as published text and does not contain any formal structure suitable for synthesizing. In a formal structure, information can be summarized, used to help locate meaningful text, and combined with other text to provide new insights. This article shows how to convert unstructured written text into structured data using OpenCalais, which is a public general-purpose text-extraction service that uses a combination of statistical and grammatical analysis to extract meaning. OpenCalais is not the only solution available for extracting meaning from text, but it is the only publicly available web service. Information Extraction. The simplest way to categorize a document or paragraph is to use word associations. For example, if the words earnings and acquired are used in a document, it is likely a document about business finances. Furthermore, if the word 'Reuters' is mostly used only in business finance documents, then other documents containing this word are likely to also be about business finances. This technique is called statistical analysis and is commonly used for document categorization. Statistical analysis is an OpenCalais technique to categorize");
for (CalaisObject entity : res.getEntities()) {
    out.println(entity.getField("_type") + ":" 
                       + entity.getField("name")+"<br>");
  }
for (CalaisObject topic : res.getTopics()) {
    out.println(topic.getField("categoryName")+"<br>");
  }
for (CalaisObject tags : res.getSocialTags()){
    out.println(tags.getField("_typeGroup") + ":" 
                       + tags.getField("name")+"<br>");
  }
%>
</body>
</html>