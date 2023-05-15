package stopwords;

import java.io.*;
import java.util.*;

import edu.stanford.nlp.tagger.maxent.*;

public class GetCollocations {
	public static ArrayList<String> GetCollocations(String text) throws IOException, ClassNotFoundException{
	    //MaxentTagger tagger = new MaxentTagger("Y:/Documents/MyDoc/MyDocCloneDrive/HIIT/Work/Projects/MailVis/code/Email/EmailSearch/src/stopwords/stanford-postagger-2013-11-12/models/english-left3words-distsim.tagger");
	    MaxentTagger tagger = new MaxentTagger("/Users/chenhe/eclipse-workspace/EmailSearch/src/stopwords/stanford-postagger-2013-11-12/models/english-left3words-distsim.tagger");
		//MaxentTagger tagger = new MaxentTagger("webapps/EmailSearch/WEB-INF/classes/stopwords/stanford-postagger-2013-11-12/models/english-left3words-distsim.tagger");
	    //String[] tagged = tagger.tagString(text).split("\\s+");
	    String[] tagged = tagger.tagString(text).split("[\\W]");
	    ArrayList<String> collocations = new ArrayList();
	    Stopwords sw = new Stopwords();
	    JazzySpellChecker SpellChecker = new JazzySpellChecker();
	    
	    for (int i = 0; i < tagged.length; i++) {
	        String pot = tagged[i].substring(tagged[i].indexOf("_") + 1);
	        if (_isNoun(pot) || _isAdjective(pot)) {
            	if((i+1)<tagged.length){
		            pot = tagged[i + 1].substring(tagged[i + 1].indexOf("_") + 1);
		            if (_isNoun(pot) || _isAdjective(pot)) {
		                if((i+2)<tagged.length)
		                {
			                pot = tagged[i + 2].substring(tagged[i + 2].indexOf("_") + 1);
			                if (_isNoun(pot)) {
			                	if(!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i]))
			                			&&!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i+1]))
			                			&&!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i+2]))
			                			&&!collocations.contains(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1]) + " " + GetWordWithoutTag(tagged[i + 2])))
			                		collocations.add(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1]) + " " + GetWordWithoutTag(tagged[i + 2]));
			                	i+=2;
			                }
			                else{
			                	if(!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i]))
			                			&&!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i+1]))
			                			&&!collocations.contains(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1])))
			                		collocations.add(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1]));
			                	i++;
			                }
		                }
		                else{
		                	if(!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i]))
		                			&&!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i+1]))
		                			&&!collocations.contains(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1])))
		                		collocations.add(GetWordWithoutTag(tagged[i]) + " " + GetWordWithoutTag(tagged[i + 1]));
			                i++;
		                }            
		            }
		            else
		            {
		            	if(!sw.is(GetWordWithoutTag(tagged[i]))&&SpellChecker.isCorrect(GetWordWithoutTag(tagged[i]))
		            			&&!collocations.contains(GetWordWithoutTag(tagged[i]))
		            			&&_isNoun(tagged[i].substring(tagged[i].indexOf("_") + 1))
		            			&&GetWordWithoutTag(tagged[i]).length()>3)
		            		collocations.add(GetWordWithoutTag(tagged[i]));
		            }
		            //i+=1;
	            } 
	        }
	    }
	    return collocations;

	}

public static String GetWordWithoutTag(String wordWithTag){
    String wordWithoutTag = wordWithTag.substring(0,wordWithTag.indexOf("_")).toLowerCase();
    return wordWithoutTag;
}

private static Boolean  _isNoun(String pot) {
    if(pot.equals("NN") || pot.equals("NNS") || pot.equals("NNP") || pot.equals("NNPS")) return true;
    else return false;
}

private static Boolean _isAdjective(String pot){
    if(pot.equals("JJ") || pot.equals("JJR") || pot.equals("JJS")) return true;
    else return false;
}

public static void main(String[] args) {

	Stopwords sw = new Stopwords();
    JazzySpellChecker SpellChecker = new JazzySpellChecker();
	try {
		ArrayList<String> GC = GetCollocations.GetCollocations("a bit tough I suppose but we need it urgently, and I want to get");
		for (int i=0 ; i<GC.size();i++)
		{
			System.out.println(GC.get(i));
		}
	} catch (ClassNotFoundException | IOException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
		
	
}

}
