import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;

import static java.lang.System.exit;

public class Parser {
    ArrayList<String[]> rows;

    public Parser() {
    }

    public ArrayList<ArrayList<String>> readFile(String fileToParse) {
        List<String> parsedInfo = new ArrayList<String>();

        // Read the train file.
        try (BufferedReader br = new BufferedReader(new FileReader(fileToParse))) {
            String line;
            while (((line = br.readLine()) != null)) {
                parsedInfo.add(line);
            }
        } catch (Exception e) {
            System.out.print(e.getMessage());
            exit(1);
        }

        // Parse the parsed info:
        ArrayList<ArrayList<String>> data = new ArrayList<ArrayList<String>>();
        for (String line : parsedInfo) {
            ArrayList<String> splitRow = new ArrayList<String>();
            for (String word : line.split("\t")) {
                splitRow.add(word);
            }
            data.add(splitRow);
        }

        return data;

        //int i = 0;
        //for (i = 0; i<rows.size(); i++) {
        //    for (String s : rows.get(i)) {
        //        System.out.println(s);
        //    }
        //}
    }
}
