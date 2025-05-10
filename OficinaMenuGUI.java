//   OficinaMenuGUI.java  //

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.ArrayList;

public class OficinaMenuGUI extends JFrame {

    private JTextArea outputArea;
    private String servicoSelecionado = "";
    private String mecanicoSelecionado = "";
    private ArrayList<String> argumentosOrcamento = new ArrayList<>();

    public OficinaMenuGUI() {
        setTitle("Oficina Ganâncio - Menu Principal");
        setSize(800, 700);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JPanel buttonPanel = new JPanel(new GridLayout(7, 1, 10, 10));

        // Botões principais
        JButton listarItemsQuantButton = new JButton("1. Listar Items por Categoria-Preço");
        JButton listarItemsPrecoButton = new JButton("2. Listar Items por Categoria-Quantidade");
        JButton listarItemsCustoButton = new JButton("3. Listar Items por Categoria-Nome");
        JButton listarServicosButton = new JButton("4. Listar Serviços");
        JButton listarDescontosButton = new JButton("5. Ver Descontos");
        JButton listarMecanicosButton = new JButton("6. Ver Mecânicos");

        buttonPanel.add(listarItemsQuantButton);
        buttonPanel.add(listarItemsPrecoButton);
        buttonPanel.add(listarItemsCustoButton);
        buttonPanel.add(listarServicosButton);
        buttonPanel.add(listarDescontosButton);
        buttonPanel.add(listarMecanicosButton);

        // Área de output
        outputArea = new JTextArea();
        outputArea.setEditable(false);
        JScrollPane scrollPane = new JScrollPane(outputArea);

        // Painel para orçamento
        JPanel orcamentoPanel = new JPanel();
        orcamentoPanel.setLayout(new BoxLayout(orcamentoPanel, BoxLayout.Y_AXIS));

        orcamentoPanel.setBorder(BorderFactory.createTitledBorder("Gerar Orçamento"));

        // Serviços
        orcamentoPanel.add(new JLabel("Escolha o serviço:"));
        JPanel servicoButtonsPanel = new JPanel(new GridLayout(8, 2, 10, 10));
        servicoButtonsPanel.setPreferredSize(new Dimension(400, 200));  // largura 400, altura 300

        for (int i = 1; i <= 16; i++) {
            JButton botaoServico = new JButton("Serviço " + i);
            int finalI = i;
            botaoServico.addActionListener(e -> {
                servicoSelecionado = String.valueOf(finalI);
            });
            servicoButtonsPanel.add(botaoServico);
        }
        orcamentoPanel.add(servicoButtonsPanel);

        // Mecânicos
        orcamentoPanel.add(new JLabel("Escolha o mecânico:"));
        JPanel mecanicoButtonsPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 10, 5));

        JButton mecanico1Button = new JButton("Ganancio");
        JButton mecanico2Button = new JButton("Severo");

        mecanico1Button.addActionListener(e -> mecanicoSelecionado = "1");
        mecanico2Button.addActionListener(e -> mecanicoSelecionado = "2");

        mecanicoButtonsPanel.add(mecanico1Button);
        mecanicoButtonsPanel.add(mecanico2Button);
        orcamentoPanel.add(mecanicoButtonsPanel);

        // Horas + botão adicionar juntos
        JTextField horasField = new JTextField(5); // 5 colunas, pequeno
        JButton adicionarServicoButton = new JButton("Adicionar Serviço ao Orçamento");
        
        JPanel horasPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 10, 5));
        horasPanel.add(new JLabel("Horas necessárias:"));
        horasPanel.add(horasField);
        horasPanel.add(adicionarServicoButton);
        //  adiciona ao painel principal de orçamento
        orcamentoPanel.add(horasPanel);
        

        // Botão para gerar orçamento
        JButton gerarOrcamentoButton = new JButton("7. Gerar Orçamento");
        orcamentoPanel.add(gerarOrcamentoButton);

        // Listeners dos botões principais
        listarItemsQuantButton.addActionListener(e -> mostrarResultado("./main.exe listar_items quantidade"));
        listarItemsPrecoButton.addActionListener(e -> mostrarResultado("./main.exe listar_items preco"));
        listarItemsCustoButton.addActionListener(e -> mostrarResultado("./main.exe listar_items custo"));
        listarServicosButton.addActionListener(e -> mostrarResultado("./main.exe listar_servicos"));
        listarDescontosButton.addActionListener(e -> mostrarResultado("./main.exe listar_descontos"));
        listarMecanicosButton.addActionListener(e -> mostrarResultado("./main.exe listar_mecanicos"));

        // Listener para adicionar serviço
        adicionarServicoButton.addActionListener(e -> {
            String horas = horasField.getText().trim();
            if (!servicoSelecionado.isEmpty() && !mecanicoSelecionado.isEmpty() && !horas.isEmpty()) {
                argumentosOrcamento.add(servicoSelecionado);
                argumentosOrcamento.add(mecanicoSelecionado);
                argumentosOrcamento.add(horas);
                outputArea.append("Adicionado: Serviço " + servicoSelecionado + ", Mecânico " + mecanicoSelecionado + ", Horas " + horas + "\n");
                horasField.setText("");
            } else {
                JOptionPane.showMessageDialog(this, "Por favor selecione serviço, mecânico e insira horas.");
            }
        });

        // Listener para gerar orçamento
        gerarOrcamentoButton.addActionListener(e -> {
            if (argumentosOrcamento.size() % 3 != 0 || argumentosOrcamento.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Nenhum serviço válido adicionado!");
                return;
            }
            try {
                ArrayList<String> comando = new ArrayList<>();
                comando.add("./main.exe");
                comando.add("gerar_orcamento");
                comando.addAll(argumentosOrcamento);

                ProcessBuilder builder = new ProcessBuilder(comando);
                builder.redirectErrorStream(true);
                Process process = builder.start();
                process.waitFor();

                File orcamentoFile = new File("orcamento.txt");
                if (!orcamentoFile.exists()) {
                    JOptionPane.showMessageDialog(this, "Erro: orcamento.txt não encontrado.");
                    return;
                }

                BufferedReader reader = new BufferedReader(new FileReader(orcamentoFile));
                StringBuilder conteudo = new StringBuilder();
                String linha;
                while ((linha = reader.readLine()) != null) {
                    conteudo.append(linha).append("\n");
                }
                reader.close();

                outputArea.setText(conteudo.toString());
                argumentosOrcamento.clear(); // Limpa a seleção depois de gerar
            } catch (Exception ex) {
                ex.printStackTrace();
                JOptionPane.showMessageDialog(this, "Erro ao gerar orçamento: " + ex.getMessage());
            }
        });

        // Montar a janela
       // Novo painel para o topo
       // Novo painel de listagem de botões (esquerda)
        JPanel botoesListagemPanel = new JPanel();
        botoesListagemPanel.setLayout(new BoxLayout(botoesListagemPanel, BoxLayout.Y_AXIS));
       
        botoesListagemPanel.add(listarItemsQuantButton);
        botoesListagemPanel.add(listarItemsPrecoButton);
        botoesListagemPanel.add(listarItemsCustoButton);
        botoesListagemPanel.add(listarServicosButton);
        botoesListagemPanel.add(listarDescontosButton);
        botoesListagemPanel.add(listarMecanicosButton);

        // Painel de orçamento (direita) já está: orcamentoPanel

        // Split entre botões (1/3) e orçamento (2/3)
        JSplitPane topSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, botoesListagemPanel, orcamentoPanel);
        topSplitPane.setResizeWeight(0.33); // 1/3 para botões
        topSplitPane.setDividerLocation(250); // posição inicial da divisão

       /// Divisão vertical: cima (botões+orcamento), baixo (área de output)
        JSplitPane verticalSplit = new JSplitPane(JSplitPane.VERTICAL_SPLIT, topSplitPane, scrollPane);
        verticalSplit.setResizeWeight(0.4); // 40% cima, 60% baixo
        verticalSplit.setDividerLocation(280); // posição inicial da divisão

        mainPanel.add(verticalSplit, BorderLayout.CENTER);





        add(mainPanel);
        setVisible(true);
    }

    private void mostrarResultado(String comando) {
        String resultado = IntegradorOCaml.executarComando(comando);
        outputArea.setText(resultado);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new OficinaMenuGUI());
    }
}
