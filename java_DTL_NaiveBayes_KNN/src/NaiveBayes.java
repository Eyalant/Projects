import sun.reflect.generics.tree.Tree;

import java.util.ArrayList;
import java.util.Map;
import java.util.TreeMap;

public class NaiveBayes implements Algorithm {
    ArrayList<ArrayList<String>> trainingData, testData;

    /* A constructor for NB. It gets the training data and the test data. */
    public NaiveBayes(ArrayList<ArrayList<String>> trainingData, ArrayList<ArrayList<String>> testData) {
        this.trainingData = trainingData;
        this.testData = testData;
    }

    public ArrayList<String> getClassifiers() {
        int j = 0;

        // Get the classifiers:
        ArrayList<String> classifiers = new ArrayList<String>();
        String class1 = trainingData.get(1).get(trainingData.get(1).size() - 1);
        classifiers.add(class1);
        for (j = 2; j < trainingData.size(); j++) {
            if (!trainingData.get(j).get(trainingData.get(j).size() - 1).equals(class1)) {
                String class2 = trainingData.get(j).get(trainingData.get(j).size() - 1);
                classifiers.add(class2);
                break;
            }
        }

        return classifiers;
    }







    public void run(ArrayList<String> naive_output_decisions) {
        /* For each test data:
        /* For each classifier:
            Calculate P(c)
            Calculate P(D|c): for each feature, calculate P(Feature|classifier) and multiply all.
                              P(Feature|classifier) is # of feature AND classifier / # of classifier (w/ smoothing).

            Do P(D|c)P(c)

        In the end, choose the max P(D|c)P(c) */
        int j = 1, accuracyCounter = 0;
        ArrayList<String> classifiers = getClassifiers();


        /// CHANGE TESTDATA.SIZE()-1 to 1!!!!!!!!!!!!!!
        for (j=1; j<testData.size() ; j++) {
            TreeMap<Double,String> classProbabilities = new TreeMap<Double,String>();
            for (String c : classifiers) {
                // Calculate P(c)
                double prior = calcPrior(c);

                // Calculate P(D|c)
                double d_given_c = calcDPC(c, testData.get(j));
                if (!classProbabilities.containsKey(d_given_c * prior)) {
                    classProbabilities.put(d_given_c * prior, c);
                }
                else {
                    // This probability already exists in the list. Choose the positive
                    // classification in this case.

                    // If the classification that was already in the list is positive:
                    if (classProbabilities.get(d_given_c * prior).equals("yes")
                            || classProbabilities.get(d_given_c * prior).equals("true")) {
                        continue;
                    }
                    // If the new classification is the positive one:
                    else {
                        if (c.equals("yes") || c.equals("true")) {
                            classProbabilities.put(d_given_c * prior, c);
                        }
                    }
                }
            }

            //for (Map.Entry<Double, String> entry : classProbabilities.entrySet()) {
            //    System.out.println("Key " + entry.getKey() + " Value " + entry.getValue());
            //}

            // Choose max classification:
            String classification = classProbabilities.lastEntry().getValue();
            naive_output_decisions.add(classification);

            // If the prediction was accurate, add it to the counter:
            if (classification.equals(testData.get(j).get(testData.get(j).size() - 1))) {
                accuracyCounter++;
            }

            classProbabilities.clear();
        }
        // Check accuracy:
        double accuracy = ((double) accuracyCounter / (double) (testData.size() - 1));
        double round = Math.round(accuracy * 100.0) / 100.0;
        naive_output_decisions.add(String.valueOf(round));
    }








    public double calcPrior(String classifier) {
        int classifier_count = 0;
        int i = 1;

        // Count classifier appearences
        for (i = 1; i < trainingData.size(); i++) {
            if (trainingData.get(i).get(trainingData.get(i).size() - 1).equals(classifier)) {
                classifier_count++;
            }
        }

        return ((double) classifier_count / (double)(trainingData.size() - 1));
    }



    public double calcDPC(String classifier, ArrayList<String> testVector) {

        // Calculate P(D|c): for each feature, calculate P(Feature|classifier) and multiply all.
        // P(Feature|classifier) is # of feature AND classifier / # of classifier (w/ smoothing).

        int j;
        double pdc = 1;

        // For each feature in the test vector:
        for (j = 0; j < (testVector.size()-1); j++) {
            int i = 1;
            int feature_and_classifier_count = 0;
            int classifier_count = 0;

            // Get K, the # of options for a feature
            ArrayList<String> possibleValues = new ArrayList<String>();
            for (i=1; i<trainingData.size(); i++) {
                if (!possibleValues.contains(trainingData.get(i).get(j))) {
                    possibleValues.add(trainingData.get(i).get(j));
                }
            }
            int k = possibleValues.size();

            // Count number of feature AND classifier apps in training:
            for (i=1; i<trainingData.size(); i++) {
                if (trainingData.get(i).get(j).equals(testVector.get(j))
                        && trainingData.get(i).get(trainingData.get(i).size() - 1).equals(classifier)) {
                    feature_and_classifier_count++;
                }
            }

            // Count number of classifier apps in training:
            for (i=1; i<trainingData.size(); i++) {
                if (trainingData.get(i).get(trainingData.get(i).size() - 1).equals(classifier)) {
                    classifier_count++;
                }
            }

            double feature_pdc = ((double) (feature_and_classifier_count + 1) / (double) (classifier_count + k));
            pdc *= feature_pdc;
        }

        return pdc;
    }
}
