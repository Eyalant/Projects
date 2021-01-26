import com.sun.org.apache.xpath.internal.operations.Bool;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.*;

import static java.lang.System.exit;

public class DTL implements Algorithm {
    ArrayList<ArrayList<String>> trainingData, testData;

    public DTL(ArrayList<ArrayList<String>> trainingData, ArrayList<ArrayList<String>> testData) {
        this.trainingData = trainingData;
        this.testData = testData;
    }

    public void run(ArrayList<String> dtl_output_decisions) {
        mainDTL(dtl_output_decisions);
    }

    public DTL_Node mainDTL(ArrayList<String> dtl_output_decisions) {
        ArrayList<String> attributes = getAttributes();
        ArrayList<ArrayList<String>> examples = makeDeepCopy(trainingData);

        // Remove the row of attributes, so that examples from now on will be
        // vectors only:
        examples.remove(0);
        String default_value = mode(examples);
        DTL_Node tree = doDTL(examples, attributes, default_value);

        int i = 1;
        int accuracyCounter = 0;
        for (i = 1; i < testData.size(); i++) {
            String classification = runTestVectorOnTree(tree,testData.get(i));
            dtl_output_decisions.add(classification);
            if (classification.equals(testData.get(i).get(testData.get(i).size() - 1))) {
                accuracyCounter++;
            }
        }

        double accuracy = ((double) accuracyCounter / (double) (testData.size() - 1));
        double round = Math.round(accuracy * 100.0) / 100.0;
        dtl_output_decisions.add(String.valueOf(round));

        StringBuilder string_to_output = printTree(tree, 0);
        File file = new File("output_tree.txt");
        BufferedWriter writer = null;
        try {
            writer = new BufferedWriter(new FileWriter(file));
            writer.write(string_to_output.toString());
        }
        catch (Exception e) {
            System.out.print(e.getMessage());
            exit(1);
        }
        finally {
            if (writer != null) {
                try {
                    writer.close();
                }
                catch (Exception e) {
                    System.out.print(e.getMessage());
                    exit(1);
                }
            }
        }

        return tree;
    }


    public DTL_Node doDTL(ArrayList<ArrayList<String>> examples, ArrayList<String> attributes, String default_value) {

        // Base cases:
        if (examples.isEmpty()) {
            return new DTL_Node(null, null, default_value);
        }
        else if (examplesSameClass(examples)) {
            // Return one of the classifications (they're all the same
            // so it doesn't matter which one):
            return new DTL_Node(null, null, examples.get(0).get(examples.get(0).size() - 1));
        }
        else if (attributes.isEmpty()) {
            return new DTL_Node(null, null, mode(examples));
        }
        else {
            String best = chooseBestAttribute(attributes, examples);
            //System.out.println(best);
            // New tree with root "best"
            DTL_Node tree = new DTL_Node(best, new ArrayList<DTL_Label>(), null);
            ArrayList<String> possibleLabelsForBest = getPossibleLabelsForBest(best);
            Collections.sort(possibleLabelsForBest);
            // Create a label for each one:
            for (String label : possibleLabelsForBest) {
                DTL_Label l = new DTL_Label(label,null);
                tree.list_of_labels.add(l);

                ArrayList<ArrayList<String>> value_examples = getExamplesWithValue(examples, best, label);
                ArrayList<String> attributes_without_best = new ArrayList<String>(attributes);
                attributes_without_best.remove(best);
                //System.out.println(label);
                //System.out.println(examples.size());
                l.child = doDTL(value_examples, attributes_without_best, mode(examples));
            }

            return tree;
        }


    }

    public String runTestVectorOnTree(DTL_Node tree, ArrayList<String> testVector) {
        // Find what column is the attribute:
        int i = 0, columnOfBest = -1;
        for (i = 0; i < trainingData.get(0).size() - 1; i++) {
            if (trainingData.get(0).get(i).equals(tree.attribute)) {
                columnOfBest = i;
                break;
            }
        }

        // Get value/label matching to tree.attribute:
        String testVectorLabel = testVector.get(columnOfBest);
        for (DTL_Label l : tree.list_of_labels) {
            if (l.label.equals(testVectorLabel)) {
                if (l.child.list_of_labels == null) {
                    return l.child.classification;
                }
                else {
                    return runTestVectorOnTree(l.child, testVector);
                }
            }
        }

        return "placeholder";
    }

    public StringBuilder printTree(DTL_Node tree, int recursions) {
        StringBuilder sb = new StringBuilder();
        int i = 0;
        for (DTL_Label label : tree.list_of_labels) {
            for (i = 0; i < recursions; i++) {
                sb.append("\t");
            }
            if (recursions != 0) {
                sb.append("|");
            }
            sb.append(tree.attribute);
            sb.append("=");
            sb.append(label.label);
            if (label.child.list_of_labels == null) {
                sb.append(":");
                sb.append(label.child.classification);
                sb.append("\n");
            }
            else {
                    sb.append("\n");
                    sb.append(printTree(label.child, recursions+1));
            }
        }
        return sb;
    }

    public String chooseBestAttribute(ArrayList<String> attributes, ArrayList<ArrayList<String>> examples) {
        // A treemap (to keep it sorted):
        TreeMap<Double, String> gains = new TreeMap<Double, String>();

        // Calc general entropy:
        int class1_count = 0, class2_count = 0;
        String class1;
        class1 = examples.get(0).get(examples.get(0).size() - 1);

        // Get class1 and class2 count in general:
        for (ArrayList<String> vector : examples) {
            if (vector.get(vector.size() - 1).equals(class1)) {
                class1_count++;
            }
            else {
                class2_count++;
            }
        }
        double probability_for_class1 = (double) class1_count / (double) examples.size();
        double probability_for_class2 = (double) class2_count / (double) examples.size();
        double general_entropy = calcEntropy(probability_for_class1, probability_for_class2);

        for (String attr : attributes) {
            // Find how many possible values there are for this attribute
            ArrayList<String> possibleLabels = getPossibleLabelsForBest(attr);
            // Calculate the attribute's probabilities for each value
            double entropy_by_values = 0;
            for (String label : possibleLabels) {
                double prob_for_attr_is_label_with_class1, prob_for_attr_is_label_with_class2, prob_for_choosing_label;
                ArrayList<ArrayList<String>> examples_with_value = getExamplesWithValue(examples, attr, label);
                // Out of those examples, filter the ones that have class1 and class2:
                class1_count = 0;
                class2_count = 0;
                class1 = examples.get(0).get(examples.get(0).size() - 1);
                for (ArrayList<String> vector : examples_with_value) {
                    if (vector.get(vector.size() - 1).equals(class1)) {
                        class1_count++;
                    }
                    else {
                        class2_count++;
                    }
                }
                if (examples_with_value.size() == 0) {
                    continue;
                }
                else {
                    prob_for_attr_is_label_with_class1 = (double) class1_count / (double) examples_with_value.size();
                    prob_for_attr_is_label_with_class2 = (double) class2_count / (double) examples_with_value.size();
                    prob_for_choosing_label = (double) (class1_count + class2_count) / (double) examples.size();
                    double value_entropy = (double) prob_for_choosing_label * calcEntropy(prob_for_attr_is_label_with_class1, prob_for_attr_is_label_with_class2);
                    entropy_by_values += value_entropy;
                }
            }
            double info_gain = general_entropy - entropy_by_values;
            if (!gains.containsKey(info_gain)) {
                gains.put(info_gain, attr);
            }
        }
        String returned_val = gains.lastEntry().getValue();
        return gains.lastEntry().getValue();
    }


    public double calcEntropy(double prob1, double prob2) {
        if (prob1 == 0) {
            double log2_prob2 = Math.log(prob2)/Math.log(2);
            double prob2_entropy = -1*prob2*log2_prob2;
            return prob2_entropy;
        }
        if (prob2 == 0) {
            double log2_prob1 = Math.log(prob1)/Math.log(2);
            double prob1_entropy = -1*prob1*log2_prob1;
            return prob1_entropy;
        }
        double log2_prob1 = Math.log(prob1)/Math.log(2);
        double prob1_entropy = -1*prob1*log2_prob1;
        double log2_prob2 = Math.log(prob2)/Math.log(2);
        double prob2_entropy = -1*prob2*log2_prob2;
        return (prob1_entropy + prob2_entropy);
    }


    public ArrayList<ArrayList<String>> getExamplesWithValue(ArrayList<ArrayList<String>> examples, String best, String label) {
        ArrayList<ArrayList<String>> subset = new ArrayList<ArrayList<String>>();

        // Find what column is the attribute:
        int i = 0, columnOfBest = -1;
        for (i = 0; i < trainingData.get(0).size() - 1; i++) {
            if (trainingData.get(0).get(i).equals(best)) {
                columnOfBest = i;
                break;
            }
        }

        // Get the elements of examples with best = label:
        for (ArrayList<String> vector : examples) {
            if (vector.get(columnOfBest).equals(label)) {
                subset.add(vector);
            }
        }

        return subset;
    }




    public ArrayList<String> getPossibleLabelsForBest(String best) {
        ArrayList<String> possible_labels = new ArrayList<String>();
        int columnOfBest = -1;

        // Find what column is the attribute:
        int i = 0;
        for (i = 0; i < trainingData.get(0).size() - 1; i++) {
            if (trainingData.get(0).get(i).equals(best)) {
                columnOfBest = i;
                break;
            }
        }

        // Get the possible labels (values) for this attribute:
        for (i = 1; i < trainingData.size(); i++) {
            if (!possible_labels.contains(trainingData.get(i).get(columnOfBest))) {
                possible_labels.add(trainingData.get(i).get(columnOfBest));
            }
        }

        return possible_labels;
    }

    /* This function makes a deep copy of the given ArrayList (we'll need to sort a new list
    * for each test data). */
    public ArrayList<ArrayList<String>> makeDeepCopy(ArrayList<ArrayList<String>> original) {
        ArrayList<ArrayList<String>> copy = new ArrayList<ArrayList<String>>();
        int i = 0;
        for (i = 0; i < original.size(); i++) {
            ArrayList<String> al = new ArrayList<String>(original.get(i));
            copy.add(al);
        }
        return copy;
    }

    public Boolean examplesSameClass(ArrayList<ArrayList<String>> examples) {
        int i = 1;
        String classification = examples.get(0).get(examples.get(0).size() - 1);
        for (i = 1; i<examples.size(); i++) {
            if (!examples.get(i).get(examples.get(i).size() - 1).equals(classification)) {
                return false;
            }
        }

        return true;
    }

    public ArrayList<String> getAttributes() {
        ArrayList<String> attr = new ArrayList<String>();
        int i = 0;
        for (i = 0; i < this.trainingData.get(0).size() - 1; i++) {
            attr.add(this.trainingData.get(0).get(i));
        }
        return attr;
    }

    public String mode(ArrayList<ArrayList<String>> examples) {
        // Get the majority of classifications:

        // By counting how many there are for each one
        int j, class1_count = 0, class2_count = 0;
        String class1 = examples.get(0).get(examples.get(0).size() - 1);
        String class2 = "placeholder";

        for (j = 1; j < examples.size(); j++) {
            if (!examples.get(j).get(examples.get(j).size() - 1).equals(class1)) {
                class2 = examples.get(j).get(examples.get(j).size() - 1);
            }
        }
        j = 0;

        for (j = 0; j < examples.size(); j++) {
            if (examples.get(j).get(examples.get(j).size() - 1).equals(class1)) {
                class1_count++;
            }
            else if (examples.get(j).get(examples.get(j).size() - 1).equals(class2)) {
                class2_count++;
            }
        }

        if (class1_count == class2_count) {
            // Break tie by choosing "yes"/"true":
            if (class1.equals("yes") || class1.equals("true")) {
                return class1;
            }
            else if (class2.equals("yes") || class2.equals("true")) {
                return class2;
            }
        }
        else if (class1_count > class2_count) {
            return class1;
        }
        else if (class1_count < class2_count) {
            return class2;
        }

        return "Could not decide";
    }
}
