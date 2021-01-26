import java.io.BufferedReader;
import java.io.FileReader;
import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import static java.lang.System.exit;

public class KNN implements Algorithm {
    ArrayList<ArrayList<String>> trainingData, testData;

    /* A constructor for KNN. It gets the training data and the test data. */
    public KNN(ArrayList<ArrayList<String>> trainingData, ArrayList<ArrayList<String>> testData) {
        this.trainingData = trainingData;
        this.testData = testData;
    }

    /* This function makes a deep copy of the given ArrayList (we'll need to sort a new list
     * for each test data). */
    public ArrayList<ArrayList<String>> makeDeepCopy(ArrayList<ArrayList<String>> original) {
        ArrayList<ArrayList<String>> copy = new ArrayList<ArrayList<String>>();
        int i = 0;
        for (i = 0; i < original.size(); i++) {
            ArrayList<String> al = new ArrayList<String>(original.get(i));
            // al.add(Integer.toString(i));
            copy.add(al);
        }
        return copy;
    }

    public void run(ArrayList<String> knn_output_decisions) {
        // Initialize value of K
        int k = 5;
        int accuracyCounter = 0;

        // Define a comparator between the hamming distances:
        Comparator<ArrayList<String>> comparator = new Comparator<ArrayList<String>>() {
            @Override
            public int compare(ArrayList<String> o1, ArrayList<String> o2) {
                // If o1's hamming distance is bigger, return 1:
                if (Integer.parseInt(o1.get(o1.size() - 1)) > Integer.parseInt(o2.get(o2.size() - 1))) {
                    return 1;
                }

                // If o1's hamming is smaller, return -1:
                if (Integer.parseInt(o1.get(o1.size() - 1)) < Integer.parseInt(o2.get(o2.size() - 1))) {
                    return -1;
                }

                // If it's the same, return 0 (the Collections.sort() method will make sure it's stable):
                if (Integer.parseInt(o1.get(o1.size() - 1)) == Integer.parseInt(o2.get(o2.size() - 1))) {
                    return 0;
                }

                return 0;
            }
        };

        // For each testData row:
        int j = 1;
        for (j = 1; j < testData.size(); j++) {

            // Make a deep copy of the training data (we'll add hamming distances and sort it later):
            ArrayList<ArrayList<String>> copy = makeDeepCopy(trainingData);

            // Iterate from 1 to total number of training data points
            int i = 1;
            for (i = 1; i < copy.size(); i++) {

                // Calculate and add the hamming distance as a last column to each row
                String hammingDistance = calcHamming(copy.get(i), testData.get(j));
                copy.get(i).add(hammingDistance);
            }

            // Sort the data rows by hamming distances (ignore row 0 as it's the parameters):
            Collections.sort(copy.subList(1, copy.size()), comparator);

            // Decide the majority between the K first (smallest) distances and return it:
            String classification = getClassFromMajority(copy, k);
            knn_output_decisions.add(classification);
            if (classification.equals(testData.get(j).get(testData.get(j).size() - 1))) {
                accuracyCounter++;
            }
        }

        // Check accuracy:
        double accuracy = ((double) accuracyCounter / (double) (testData.size() - 1));
        double round = Math.round(accuracy * 100.0) / 100.0;
        knn_output_decisions.add(String.valueOf(round));
    }


    /* This function calculates and returns the hamming distance between the given training vector and
    the given test vector. */
    public String calcHamming(ArrayList<String> trainingVector, ArrayList<String> testVector) {
        int hammingDistance = 0, i = 0;

        // For each feature, check if it's the same
        for (i = 0; i < trainingVector.size() - 1; i++) {
            if (!trainingVector.get(i).equals(testVector.get(i))) {
                hammingDistance += 1;
            }
        }

        return Integer.toString(hammingDistance);
    }


    /* This function get the k nearest neighbours from training data list (now sorted
     * by hamming distances), and selects the majority of the classifications from
      * these K neighbours. */
    public String getClassFromMajority(ArrayList<ArrayList<String>> trainingData, int k) {

        // We access size() - 2 to get the classification because now the last element
        // is the hamming distance.
        String class1 = trainingData.get(1).get(trainingData.get(1).size() - 2);
        String class2 = "placeholder";
        int i = 1, class1_count = 0, class2_count = 0;

        // Go over k first rows in sorted array:
        for (i = 1; i<k+1 ; i++) {
            // Access the classification in the row:
            if (trainingData.get(i).get(trainingData.get(i).size() - 2).equals(class1)) {
                class1_count += 1;
            }

            else {
                class2 = trainingData.get(i).get(trainingData.get(i).size() - 2);
                class2_count += 1;
            }
        }

        // Return the appropriate classification:
        if (class1_count > class2_count) {
            return class1;
        }
        else if (class2_count > class1_count) {
            return class2;
        }

        // If there's a tie, break it by taking the positive value:
        else if (class1_count == class2_count) {
            if (class1.equals("yes") || class1.equals("true")) {
                return class1;
            }
            else if (class2.equals("yes") || class2.equals("true")) {
                return class2;
            }
        }

        return "Could not decide";
    }
}
