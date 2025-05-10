1-No PowerShell integrado do Visual Studio Code, activar o ambiente OCaml 4.14.0 com o comando:

(& opam env --switch=4.14.0) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }

2-Compilar o programa com:
ocamlc -o main.exe str.cma main.ml
javac *.java

Isto cria o ficheiro main.exe, que será chamado pelo Java.

3-Iniciar o GUI do programa:
java -cp . OficinaMenuGUI

4-Comandos bash no powershell

Para listar todos os items no powershell:
./main.exe listar_items

Para listar itens ordenados:
./main.exe listar_items_ordenados

listagem por quantidade em stock
./main.exe listar_items quantidade

listagem pelo preço
./main.exe listar_items preco

listagem pelo custo:
./main.exe listar_items custo

listagem dos serviços:
./main.exe listar_servicos

listagem dos descontos:
./main.exe listar_descontos

listagem dos mecanicos:
./main.exe listar_mecanicos

gerar orçamento:
./main.exe gerar_orcamento 1 1 0.5 3 1 0.5 5 2 1.0
ou
./main.exe gerar_orcamento <serviço ID> <mecânico ID> <Horas necessárias> <serviço ID> <mecânico ID> <Horas necessárias>

O OCaml gera o orcamento.txt ao calcular um orçamento.
O conteúdo do orcamento.txt é automaticamente mostrado no GUI.

Compilar os testes dos REGEX's
ocamlc str.cma main_test_regex.ml -o main_test_regex.exe
./main_test_regex.exe


 