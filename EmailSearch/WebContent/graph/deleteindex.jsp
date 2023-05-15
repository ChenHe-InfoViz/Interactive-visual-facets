<%@ page import="java.util.*" %>
<%@ page import="javax.mail.internet.*,javax.activation.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="javax.mail.*,javax.mail.search.SearchTerm"%>
<%@ page import="java.io.*"%>
<%@ page import="org.jsoup.*, org.apache.commons.io.FileUtils"%>
<%@ page import="org.apache.lucene.search.*,org.apache.lucene.misc.*,org.apache.lucene.sandbox.queries.*" %>
<%@ page import="org.apache.lucene.index.TermsEnum,org.apache.lucene.search.FuzzyTermsEnum,org.apache.lucene.queries.CommonTermsQuery" %>	
<%@ page import="org.apache.lucene.analysis.en.PorterStemFilter,org.apache.lucene.analysis.tokenattributes.*" %>
<%@ page import="org.apache.lucene.queryparser.classic.QueryParser" %>
<%@ page import="org.apache.lucene.store.Directory,org.apache.lucene.store.FSDirectory" %>
<%@ page import="org.apache.lucene.store.*,org.apache.lucene.analysis.*,org.apache.lucene.analysis.standard.*,org.apache.lucene.document.*,org.apache.lucene.index.*,org.apache.lucene.index.IndexWriterConfig.*,org.apache.lucene.util.*" %>
<% 
String username = request.getParameter("username");
String timestamp = request.getParameter("timestamp");
String rootPath = request.getParameter("rootpath");
String indexPath = rootPath + "index/"+username;
FileUtils.deleteDirectory(new File(indexPath));

String logPath =rootPath + "logs/"+username+""+timestamp;
/*
(new File(logPath+"doubleclick")).delete();
(new File(logPath+"emailselect")).delete();
(new File(logPath+"tagselected")).delete();
(new File(logPath+"tagset")).delete();
(new File(logPath+"timeselected")).delete();
(new File(logPath+"thestate")).delete();
*/
out.println(username);
%>
