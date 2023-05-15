<%@ page import="java.util.*,java.util.regex.*, javax.mail.search.*,java.text.SimpleDateFormat" %>
<%@ page import="javax.mail.internet.*,javax.activation.*, javax.mail.Part"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="javax.mail.*,javax.mail.search.SearchTerm"%>
<%@ page import="java.io.*, stopwords.*"%>
<%@ page import="org.jsoup.*, org.apache.commons.io.FileUtils"%>
<%@ page import="org.apache.lucene.search.*,org.apache.lucene.misc.*,org.apache.lucene.sandbox.queries.*" %>
<%@ page import="org.apache.lucene.index.TermsEnum,org.apache.lucene.search.FuzzyTermsEnum,org.apache.lucene.queries.CommonTermsQuery" %>	
<%@ page import="org.apache.lucene.analysis.en.PorterStemFilter,org.apache.lucene.analysis.tokenattributes.*" %>
<%@ page import="org.apache.lucene.queryparser.classic.QueryParser" %>
<%@ page import="org.apache.lucene.store.Directory,org.apache.lucene.store.FSDirectory, javax.crypto.Cipher, org.apache.lucene.store.transform.algorithm.security.*, org.apache.lucene.store.transform.algorithm.compress.*,org.apache.lucene.store.transform.algorithm.*,org.apache.lucene.store.transform.*" %>
<%@ page import="org.apache.lucene.store.*,javax.crypto.Cipher, org.apache.lucene.analysis.*,org.apache.lucene.analysis.standard.*,org.apache.lucene.document.*,org.apache.lucene.index.*,org.apache.lucene.index.IndexWriterConfig.*,org.apache.lucene.util.*" %>
<% 
String username = request.getParameter("username");
String password = request.getParameter("password");
String server = request.getParameter("server");

String rootPath = request.getParameter("rootpath");
String indexPath = rootPath + "index/"+username;

File path = new File(indexPath);
if(path.exists())
	FileUtils.deleteDirectory(new File(indexPath));
path.mkdirs();
path.setExecutable(true,false);
path.setReadable(true,false);
path.setWritable(true,false);

Properties props = System.getProperties();
Directory fsDirectory =null;
IndexWriter indexWriter =null;
Folder inbox;
Message msg[];

if(server.equals("enron")){
 		props.put("mail.host", "enron.com");
        props.put("mail.transport.protocol", "smtp");
        props.setProperty("mail.imaps.partialfetch", "false");
        props.setProperty("mail.mime.ignoreunknownencoding", "true");

	}
else{
	if(server.equals("cshelsinki"))
		props.setProperty("mail.imaps.host", "mail.cs.helsinki.fi");
	if(server.equals("gmail"))
		props.setProperty("mail.imaps.host", "imap.gmail.com");

	props.setProperty("mail.store.protocol", "imaps");
	props.setProperty("mail.imaps.port", "993");
	props.setProperty("mail.imaps.connectiontimeout", "10000000");
	props.setProperty("mail.imaps.timeout", "10000000");
	props.setProperty("mail.mime.ignoreunknownencoding", "true");
	props.setProperty("mail.imap.partialfetch", "false");
	props.setProperty("mail.imaps.partialfetch", "false");
}



try {
    Session mysession = Session.getDefaultInstance(props, null);
    Store store = mysession.getStore("imaps");

    // IMAP host for gmail.
    // Replace <username> with the valid username of your Email ID.
    // Replace <password> with a valid password of your Email ID.


    if(server.equals("enron")){
		Session mailSession = Session.getDefaultInstance(props, null);
		String inboxString;

		//determine the inbox based on entry
		if(username.equals("jeff.skilling") || username.equals("jeff.dasovich") || username.equals("larry.may") || username.equals("kenneth.lay") || username.equals("twitter")){
			inboxString = rootPath + username + "/";
		}
		else{
			inboxString = rootPath + "inbox/";
		}
		
		File inboxFile = new File(inboxString);
		Message msg3[] = new Message[inboxFile.list().length]; 
		//System.out.println(inboxFile.list().length);
		int counter=0;

		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
		Date minDate = sdf.parse("01/01/1999");

		//Date minDate = new Date(1985,1,1,1,1);
		for (File file : inboxFile.listFiles()) {
			try{
			    if (file.isFile() || !file.isHidden()) {
				    InputStream source = new FileInputStream(file);
		        	MimeMessage message = new MimeMessage(mailSession, source);
		        	if(message.getSentDate().after(minDate)){
			        	msg3[counter] = (Message) message;
					    counter++;
			        }
			    }
				}
				catch(Exception e){
					System.err.println(e);
				}
		}
		Arrays.sort(msg3, new DateComparator());
		msg=msg3;  
	}
	else{
		
		if(server.equals("cshelsinki"))
	    		store.connect("mail.cs.helsinki.fi", username, password);
		if(server.equals("gmail"))
			store.connect("imap.gmail.com", username, password);
		if(server.equals("helsinki"))
			store.connect("posti.mappi.helsinki.fi", username, password);
		if(server.equals("yahoo"))
			store.connect("imap.mail.yahoo.com", username, password);
		if(server.equals("hotmail"))
			store.connect("imap-mail.outlook.com", username, password);
		if(server.equals("hiit"))
			store.connect("imap.otaverkko.fi", username, password);
		if(server.equals("aalto"))
			store.connect("mail.aalto.fi", username, password);
		
		Folder[] f = store.getDefaultFolder().list();
		for(Folder fd:f){
		    System.out.println(">> "+fd.getName());
		}
		inbox = store.getFolder("Inbox");
		//inbox = store.getFolder("[Gmail]/Tüm Postalar");


	inbox.open(Folder.READ_ONLY);

    	//// get emails within 6 months only ///
    
    	Date current = new Date();    
    	Calendar cal = Calendar.getInstance();  
    	cal.setTime(current);  
    	cal.set(Calendar.MONTH, (cal.get(Calendar.MONTH)-12));
    	Date past = new Date();
    	past = cal.getTime();
	
    	SearchTerm olderThan = new ReceivedDateTerm(ComparisonTerm.LT, current);
    	SearchTerm newerThan = new ReceivedDateTerm(ComparisonTerm.GT, past);
    	SearchTerm andTerm = new AndTerm(olderThan, newerThan);
	
    	Message msg2[] = inbox.search(andTerm);
    	msg = msg2;
    	
    	FetchProfile fp = new FetchProfile();
    	fp.add(FetchProfile.Item.FLAGS);
    	fp.add(FetchProfile.Item.ENVELOPE);
    	fp.add(FetchProfile.Item.CONTENT_INFO);
    	fp.add("X-mailer");
    	inbox.fetch(msg, fp);
	}
	
    	//Message msg[] = inbox.getMessages();
    	/*
	int end = inbox.getMessages().length;
	int start = 1;
	if(end>2000) start = end - 2000;
	Message msg[] = inbox.getMessages(start,end);
	*/

	//// encrypt/decrypt directory
	/*Directory bdir = FSDirectory.open(new File(indexPath));
    	byte[] salt = new byte[16];
    	String encr_password = "lucenetransform"+MacAddress.Get();
    	DataEncryptor enc = new DataEncryptor("AES/ECB/PKCS5Padding", encr_password, salt, 128,false);
    	DataDecryptor dec = new DataDecryptor(encr_password, salt,false);

    	fsDirectory = new TransformedDirectory(bdir, enc, dec);
       */
    	
	fsDirectory =  FSDirectory.open(new File(indexPath));
	/* Create instance of analyzer, which will be used to tokenize
	the input data */
	Analyzer standardAnalyzer = new StandardAnalyzer(Version.LUCENE_45);
	IndexWriterConfig iwc = new IndexWriterConfig(Version.LUCENE_45, standardAnalyzer);
	iwc.setRAMBufferSizeMB(2000.0);
	//out.println(iwc.getRAMBufferSizeMB());
	//Create a new index
	boolean create = true;
	//Create the instance of deletion policy
	IndexDeletionPolicy deletionPolicy = new KeepOnlyLastCommitDeletionPolicy();
	if(iwc.getOpenMode() == IndexWriterConfig.OpenMode.CREATE) create=false;
	if (create) {
		iwc.setOpenMode(OpenMode.CREATE);
	} else {
		iwc.setOpenMode(OpenMode.CREATE_OR_APPEND);
	}
	
	//iwc.setDefaultWriteLockTimeout(9000000);
	indexWriter = new IndexWriter(fsDirectory,iwc);
	
	
	
    // IMAP host for yahoo.
    //store.connect("imap.mail.yahoo.com", "<username>", "<password>");


    int counter=0;
    for(Message temp_message:msg) {
		MimeMessage message = (MimeMessage)temp_message;
		
		try{
        	//// recipients
    		Address[] temp_recipients = null;
        	try{
        		temp_recipients = message.getAllRecipients();
        	}
        	catch(Exception e){writeExceptionToFile("recipients -"+e.toString(),username);}
        	String recipients="";
		try{
        		if(temp_recipients!=null)
        		{
	        		for (Address address : temp_recipients) {
	        			if(address.toString().split("@")[0].split("<").length>1)
	        			{

		        			if(!containsIllegals(address.toString().split("@")[0].split("<")[1])&&
		        				!address.toString().split("@")[0].split("<")[1].replaceAll("-", "").trim().isEmpty())
		      	  			{
		       	 			if(recipients.equals(""))	
		        					recipients=address.toString().split("@")[0].split("<")[1].replaceAll("-", "");
			        			else
		       	 				recipients=recipients+"~"+address.toString().split("@")[0].split("<")[1].replaceAll("-", "");
		      		  		}
	        			}
	        			else
	        			{

        					if(!containsIllegals(address.toString().split("@")[0])&&
        							!address.toString().split("@")[0].trim().isEmpty())
        					{
        						if(recipients.equals(""))	
        							recipients=address.toString().split("@")[0].replaceAll("-", "");
	        					else
	        	    					recipients=recipients+"~"+address.toString().split("@")[0].replaceAll("-", "");
        					}
	        			}
	        		}
        		}
        		else
        		{
        			recipients = username;
        		}
		}
		catch(Exception e)
		{writeExceptionToFile("2nd recipients -"+e.toString(),username);}

        	//// msgid, date, subject
        	String date_input =  message.getSentDate().toString();
        	Integer date = 20140101;
		try{
			String[] temp =  date_input.split(" ");
        		date_input = temp[5]+""+MonthToNumber(temp[1])+""+temp[2];
			date = Integer.parseInt(date_input);
		}
		catch(Exception e)
		{writeExceptionToFile("date -"+e.toString(),username);}
        	//out.println(date.toString()+"<br>");
        	Integer msgid;
        	if(server.equals("enron")){
        		msgid =counter;
        		counter++;
	        }
	        else{
		      msgid  = message.getMessageNumber();
		    }
        	 
        	if(msgid == null ) msgid = 0;
		String subject = message.getSubject();
        	if(subject ==null) subject = "No Subject";

        	///// sender
        	String sender = "";
		try{
        		if(message.getFrom().length>0)
        		{
        			sender = message.getFrom()[0].toString().split("@")[0];
        			if(sender.split("<").length>1&&!sender.split("<")[1].replaceAll("-", "").trim().isEmpty())
        			{
        				sender = sender.split("<")[1].replaceAll("-", "");
        			}
        		}
		}
		catch(Exception e)
		{writeExceptionToFile("sender -"+e.toString(),username);}
        	
        	/// content
        	//String content = new String(getText(message).getBytes(),"ISO-8859-1")+". "+sender+" says: "+subject+" - To : "+recipients;
        	String content = getText(message);
		if(content==null) content = sender+" says: "+subject+" - To : "+recipients;
		else content = content+". "+sender+" says: "+subject+" - To : "+recipients;		
		
        	String attachment = "no";
        	if(message.isMimeType("multipart/mixed")) attachment = "yes";
        	
        	FieldType type = new FieldType();
        	type.setIndexed(true);
        	type.setStored(true);
        	type.setStoreTermVectors(true);
        	type.setStoreTermVectorOffsets(true);
        	
        	Field senderField =
        			new TextField("from",sender,Field.Store.YES);
        	Field recipientField =
        			new TextField("to",recipients,Field.Store.YES);
        	Field msgField =
        			new IntField("msgid",msgid,Field.Store.YES);
        	Field emaildatefield = 
        			new IntField("date",date,Field.Store.YES); 
        	Field subjectField = 
        			new TextField("subject",subject,Field.Store.YES);
        	Field attachmentField = 
        			new TextField("attachment",attachment,Field.Store.YES);
        	Field contentfield = new Field("content",Jsoup.parse(content).text(),type);
        	
        	//out.println(sender+"<br>");
        	Document doc = new Document();
        	doc.add(senderField);
        	doc.add(recipientField);
        	doc.add(msgField);
        	doc.add(emaildatefield);
        	doc.add(subjectField);
        	doc.add(attachmentField);
        	doc.add(contentfield);
        	indexWriter.addDocument(doc);
        	//out.println(msgid+":<br>"+sender+"<br>"+content+"<br><br>");
		}
		catch(Exception e)
		{writeExceptionToFile("loop message -"+e.toString(),username);}

    }
	indexWriter.close();
	fsDirectory.close();

	String timestamp = String.valueOf((new Date()).getTime());
	//String logfile = "C:/Email/EmailSearch/WebContent/graph/logs/"+username+timestamp+".xml";
	//createLogFile(logfile);
	
	out.println("success_"+timestamp);

} catch (Exception e) {
	//MessagingException
	out.println(e.toString());
	if(indexWriter!=null)
	indexWriter.close();
	if(fsDirectory!=null)
	fsDirectory.close();
	//////// WRITE EXCEPTION TO FILE///////////////////////
	writeExceptionToFile("lucene -"+e.toString(),username);

	
}
/*
public static Comparator<Message> DateComparator = new Comparator<Message>() {
 
        @Override
        public int compare(Message e1, Message e2) {
        	try{
        	Date date1 = e1.getSentDate();
        	Date date2 = e2.getSentDate();

            return date1.compareTo(date2);
        }
        catch(Exception e)
		{return 0;}
    }
};
*/


%>

<%!
class DateComparator implements Comparator<Message> {
        @Override
        public int compare(Message e1, Message e2) {
        	try{
        	Date date1 = e1.getSentDate();
        	Date date2 = e2.getSentDate();

            return date1.compareTo(date2);
        }
        catch(Exception e)
		{return 0;}
	}
}

private boolean textIsHtml = false;
private String getText(Part p) throws MessagingException, IOException {
	if (p.isMimeType("text/*")) {
		String s = (String)p.getContent();
		textIsHtml = p.isMimeType("text/html");
		return s;
	}
	
	if (p.isMimeType("multipart/alternative")) {
		// prefer html text over plain text
		Multipart mp = (Multipart)p.getContent();
		String text = null;
		for (int i = 0; i < mp.getCount(); i++) {
		Part bp = mp.getBodyPart(i);
		if (bp.isMimeType("text/plain")) {
			if (text == null)
				text = getText(bp);
			continue;
			} else if (bp.isMimeType("text/html")) {
				String s = getText(bp);
				if (s != null)
					return s;
				} else {
					return getText(bp);
					}
		}
		return text;
		} else if (p.isMimeType("multipart/*")) {
			Multipart mp = (Multipart)p.getContent();
			for (int i = 0; i < mp.getCount(); i++) {
				String s = getText(mp.getBodyPart(i));
				if (s != null)
					return s;
				}
			}
	return null;
	}
public void writeExceptionToFile (String e, String username)
{
	try{
	//////// WRITE EXCEPTION TO FILE///////////////////////
	//File file = new File("C:/Email/EmailSearch/WebContent/graph/exception.txt");
	File file = new File("tomcat7/webapps/EmailSearch/exception.txt");

	FileWriter fw = new FileWriter(file.getAbsoluteFile(),true);
	BufferedWriter bw = new BufferedWriter(fw);
	bw.newLine();
	bw.write(username+":"+e);
	bw.close();
	}
	catch(Exception xe) {}
}

public boolean containsIllegals(String toExamine) {
    Pattern pattern = Pattern.compile("[:;~#@*+%{}<>\\[\\]|\"\\_^]");
    Matcher matcher = pattern.matcher(toExamine);
    return matcher.find();
}

private enum myMonth {
    Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec;
}





public String MonthToNumber(String value)
{
	String result;
	myMonth month = myMonth.valueOf(value);
	switch (month){
	case Jan:
		result = "01";
		break;
	case Feb:
		result = "02";
		break;
	case Mar:
		result = "03";
		break;
	case Apr:
		result = "04";
		break;
	case May:
		result = "05";
		break;
	case Jun:
		result = "06";
		break;
	case Jul:
		result = "07";
		break;
	case Aug:
		result = "08";
		break;
	case Sep:
		result = "09";
		break;
	case Oct:
		result = "10";
		break;
	case Nov:
		result = "11";
		break;
	case Dec:
		result = "12";
		break;
	default:
		result = "00";
	}
	return result;
}

public static void createLogFile (String filename)
{
	try {
		//File file = new File(filename);
		//file.createNewFile();
		File thestatefile = new File(filename.replace(".xml", "thestate"));
		thestatefile.createNewFile();
		File tagselectedfile = new File(filename.replace(".xml", "tagselected"));
		tagselectedfile.createNewFile();
		File timeselectedfile = new File(filename.replace(".xml", "timeselected"));
		timeselectedfile.createNewFile();
		File tagsetfile = new File(filename.replace(".xml", "tagset"));
		tagsetfile.createNewFile();
		File emailselectfile = new File(filename.replace(".xml", "emailselect"));
		emailselectfile.createNewFile();
		File doubleclickfile = new File(filename.replace(".xml", "doubleclick"));
		doubleclickfile.createNewFile();
		
		/*
		FileWriter fw = new FileWriter(file.getAbsoluteFile(),true);
		BufferedWriter bw = new BufferedWriter(fw);
		String content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
				+"<emailLog>\n"
				+"  <states>states\n"
				+"  </states>\n"
				+"  <tagEvents>tagEvents\n"
				+"  </tagEvents>\n"
				+"  <timeEvents>timeEvents\n"
				+"  </timeEvents>\n"
				+"  <tagsShown>tagsShown\n"
				+"  </tagsShown>\n"
				+"  <emailEvents>emailEvents\n"
				+"  </emailEvents>\n"
				+"  <doubleClicks>doubleClicks\n"
				+"  </doubleClicks>\n"
				+"</emailLog>";
		bw.write(content);
		bw.close();*/
	}
	catch (IOException e) {}
}
%>
