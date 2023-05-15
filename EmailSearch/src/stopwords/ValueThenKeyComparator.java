package stopwords;

import java.util.*;

public class ValueThenKeyComparator<K extends Comparable<? super K>,
V extends Comparable<? super V>>
implements Comparator<Map.Entry<K, V>> {

public int compare(Map.Entry<K, V> a, Map.Entry<K, V> b) {
int cmp1 = a.getValue().compareTo(b.getValue());
if (cmp1 != 0) {
return cmp1;
} else {
return 0;
}
}


}