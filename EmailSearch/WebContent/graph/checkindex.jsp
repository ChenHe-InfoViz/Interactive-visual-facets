<%
String username = request.getParameter("name");
String rootPath ="/Users/chenhe/eclipse-workspace/EmailSearch/WebContent/graph/";
String indexPath = rootPath + "index/"+ username;

java.io.File folderExisting = new java.io.File(indexPath);  

if (folderExisting.exists()){  
	out.print("true");  
}else{  
	out.print("false");  
}  
%>
