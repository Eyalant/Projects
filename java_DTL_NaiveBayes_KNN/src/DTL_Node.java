import java.util.ArrayList;

public class DTL_Node {
    String attribute, classification;
    ArrayList<DTL_Label> list_of_labels;

    public DTL_Node(String attribute, ArrayList<DTL_Label> list_of_labels, String classification) {
        this.attribute = attribute;
        this.classification = classification;
        this.list_of_labels = list_of_labels;
    }
}
