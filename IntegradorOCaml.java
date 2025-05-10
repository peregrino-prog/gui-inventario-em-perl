import java.io.InputStream;
import java.util.Scanner;

public class IntegradorOCaml {

    public static String executarComando(String comando) {
        StringBuilder output = new StringBuilder();
        try {
            Process process = new ProcessBuilder(comando.split(" ")).start();
            InputStream inputStream = process.getInputStream();
            Scanner scanner = new Scanner(inputStream);
            while (scanner.hasNextLine()) {
                output.append(scanner.nextLine()).append("\n");
            }
            scanner.close();
            process.waitFor();
        } catch (Exception e) {
            System.err.println("Erro ao executar comando OCaml: " + e.getMessage());
        }
        return output.toString().trim();
    }
}
