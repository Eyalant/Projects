import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.lang.reflect.Array;
import java.util.ArrayList;

import static java.lang.System.exit;

public class java_ex2 {
    public static void main(String[] args) {
        Parser p = new Parser();

        // For training and test data, return a list of lists of strings (= a list of
        // the rows/vectors in each file).
        ArrayList<ArrayList<String>> trainingData = p.readFile("TEST2/train.txt");
        ArrayList<ArrayList<String>> testData= p.readFile("TEST2/test.txt");

        // Creating an output file, calling all algorithms and placing the results there.
        StringBuilder output = new StringBuilder();
        output.append("Num\tDT\tKNN\tnaiveBase\n");

        ArrayList<String> dtl_output_decisions = new ArrayList<String>();
        DTL dtl = new DTL(trainingData, testData);
        dtl.run(dtl_output_decisions);
        ArrayList<String> knn_output_decisions = new ArrayList<String>();
        KNN knn = new KNN(trainingData, testData);
        knn.run(knn_output_decisions);
        ArrayList<String> naive_output_decisions = new ArrayList<String>();
        NaiveBayes naiveBayes = new NaiveBayes(trainingData, testData);
        naiveBayes.run(naive_output_decisions);

        int i = 0;
        for (i = 0; i < testData.size() - 1; i++) {
            output.append((i+1) + "\t");
            output.append(dtl_output_decisions.get(i) + "\t");
            output.append(knn_output_decisions.get(i) + "\t");
            output.append(naive_output_decisions.get(i) + "\n");
        }
        output.append("\t" + dtl_output_decisions.get(dtl_output_decisions.size() - 1)
                + "\t" + knn_output_decisions.get(knn_output_decisions.size() - 1)
                + "\t" + naive_output_decisions.get(naive_output_decisions.size() - 1));

        File file = new File("output.txt");
        BufferedWriter writer = null;
        try {
            writer = new BufferedWriter(new FileWriter(file));
            writer.write(output.toString());
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
    }
}
