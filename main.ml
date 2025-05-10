(**************************************************************)
(***********            Main.ml                       *********)
(*************************************************************)

open Printf
open Str

(* === Funções de preprocessamento === *)
let preprocess_line line =
  let trimmed = String.trim line in
  if String.ends_with ~suffix:"." trimmed then
    trimmed
  else
    trimmed ^ "."


(* 0. Regex para serviço (6 grupos)*)
let regex_servico =
  Str.regexp "servico([ \t]*\\([0-9]+\\),[ \t]*'\\([^']+\\)',[ \t]*\\[\\([^]]+\\)\\],[ \t]*\\([0-9]+\\),[ \t]*\\([0-9.]+\\),[ \t]*\\([0-9.]+\\))\\."


(* 1. Regex para ITEM (7 grupos) *)
let regex_item =
  Str.regexp "item[ \t]*([ \t]*\\([0-9]+\\)[ \t]*,[ \t]*'\\([^']*\\)'[ \t]*,[ \t]*'\\([^']*\\)'[ \t]*,[ \t]*'\\([^']*\\)'[ \t]*,[ \t]*\\([0-9.]+\\)[ \t]*,[ \t]*\\([0-9.]+\\)[ \t]*,[ \t]*\\([0-9]+\\)[ \t]*)[ \t]*\\.?"

(* 2. Regex para MECANICO (3 grupos) *)
let regex_mecanico =
  Str.regexp "mecanico[ \t]*([ \t]*\\([0-9]+\\)[ \t]*,[ \t]*'\\([^']*\\)'[ \t]*,[ \t]*\\([0-9.]+\\)[ \t]*)[ \t]*\\.?"

(* 3. Regex para DESCONTO (2 grupos) *)
let regex_desconto =
  Str.regexp "desconto_marca[ \t]*([ \t]*'\\([^']*\\)'[ \t]*,[ \t]*\\([0-9.]+\\)[ \t]*)[ \t]*\\.?"

let regex_desconto_mao = 
  Str.regexp "desconto_mao_obra(\\([A-Za-z]+\\)[ \t]*,[ \t]*\\([0-9.]+\\))[ \t]*:-[ \t]*\\([A-Za-z]+\\)[ \t]*\\([<>]\\)[ \t]*\\([0-9.]+\\)"

(* Funções para leitura de ficheiro *)
let read_file filename =
  let lines = ref [] in
  let channel = open_in filename in
  try
    while true do
      lines := input_line channel :: !lines
    done;
    []
  with End_of_file ->
    close_in channel;
    List.rev !lines

(* Funções para parsing de cada tipo de entrada *)

let parse_item line =
  if Str.string_match regex_item line 0 then
    Some (
      int_of_string (Str.matched_group 1 line),
      Str.matched_group 2 line,
      Str.matched_group 3 line,
      Str.matched_group 4 line,
      float_of_string (Str.matched_group 5 line),
      float_of_string (Str.matched_group 6 line),
      int_of_string (Str.matched_group 7 line)
    )
  else None

  let safe_parse_servico_with_log line =
    try
      let line_processed = preprocess_line line in
      if Str.string_match regex_servico line_processed 0 then (
        
        (* GUARDA os grupos num array *)
        let g1 = Str.matched_group 1 line_processed in
        let g2 = Str.matched_group 2 line_processed in
        let g3 = Str.matched_group 3 line_processed in
        let g4 = Str.matched_group 4 line_processed in
        let g5 = Str.matched_group 5 line_processed in
        let g6 = Str.matched_group 6 line_processed in
  
        let id = int_of_string g1 in
        let nome = g2 in
        let categorias_brutas = g3 in
        let categorias_limpas =
          categorias_brutas
          |> Str.global_replace (Str.regexp "'") ""
          |> Str.split (Str.regexp ",[ \t]*")
          |> List.map String.trim
          |> List.filter (fun s -> s <> "")
        in
        let id_mecanico = int_of_string g4 in
        let tempo = float_of_string g5 in
        let preco = float_of_string g6 in
        Some (id, nome, categorias_limpas, id_mecanico, tempo, preco)
      ) else (
        
        None
      )
    with exn ->
      Printf.eprintf "ERRO AO PARSEAR SERVICO: %s\nLinha: %s\n" (Printexc.to_string exn) line;
      None
  
  
  
  

let parse_mecanico line =
  if Str.string_match regex_mecanico line 0 then
    Some (
      int_of_string (Str.matched_group 1 line),
      Str.matched_group 2 line,
      float_of_string (Str.matched_group 3 line)
    )
  else None

let parse_desconto line =
  if Str.string_match regex_desconto line 0 then
    Some (
      Str.matched_group 1 line,
      float_of_string (Str.matched_group 2 line)
    )
  else None

(* Leitura geral *)
let carregar_items linhas = List.filter_map (fun l -> if String.starts_with ~prefix:"item(" l then parse_item l else None) linhas

let carregar_servicos linhas =
  linhas
  |> List.filter (fun l -> 
      let line_processed = preprocess_line l in
      Str.string_match regex_servico line_processed 0
    )
  |> List.filter_map safe_parse_servico_with_log



let carregar_mecanicos linhas = List.filter_map (fun l -> if String.starts_with ~prefix:"mecanico(" l then parse_mecanico l else None) linhas
let carregar_descontos linhas = List.filter_map (fun l -> if String.starts_with ~prefix:"desconto_marca(" l then parse_desconto l else None) linhas


(* 1b. Ordenar itens por categoria -> marca -> nome *)
let ordenar_items items =
  List.sort (fun (_, _, marca1, tipo1, _, _, _) (_, _, marca2, tipo2, _, _, _) ->
    match compare tipo1 tipo2 with
    | 0 -> compare marca1 marca2
    | n -> n
  ) items

let print_item (id, nome, marca, tipo, custo, preco, quantidade) =
  Printf.printf "%d;%s;%s;%s;%.2f;%.2f;%d\n" id nome marca tipo custo preco quantidade

(* 2. Peças mais lucrativas para serviços *)
let lucro custo preco desconto = (preco *. (1.0 -. desconto)) -. custo

let encontrar_melhor_peca categoria items descontos =
  let candidatas = List.filter (fun (_, _, _, tipo, _, _, _) -> tipo = categoria) items in
  let melhor = List.fold_left (fun acc item ->
    let (_, _, marca, _, custo, preco, _) = item in
    let desconto = try List.assoc marca descontos with Not_found -> 0.0 in
    match acc with
    | None -> Some (item, lucro custo preco desconto)
    | Some (_, best_lucro) ->
      let atual_lucro = lucro custo preco desconto in
      if atual_lucro > best_lucro then Some (item, atual_lucro) else acc
  ) None candidatas in
  match melhor with
  | Some (item, _) -> Some item
  | None -> None

let orcamento_items ids items servicos descontos =
  let servicos_filtrados = List.filter (fun (id, _, _, _, _, _) -> List.mem id ids) servicos in
  let categorias = List.flatten (List.map (fun (_, _, cats, _, _, _) -> cats) servicos_filtrados) in
  let categorias_unicas = List.sort_uniq String.compare categorias in
  let pecas = List.filter_map (fun cat -> encontrar_melhor_peca cat items descontos) categorias_unicas in
  List.iter print_item pecas

(* 3. Cálculo de mão de obra *)
let orcamento_mecanico ids servicos mecanicos =
  let servicos_filtrados = List.filter (fun (id, _, _, _, _, _) -> List.mem id ids) servicos in
  List.iter (fun (id, _, _, num_mecs, tempo, _) ->
    let (id_mec, _, custo_hora) = List.hd mecanicos in 
    let custo_sem_desconto = custo_hora *. tempo *. (float_of_int num_mecs) in
    let desconto =
      if tempo < 0.25 then custo_sem_desconto *. 0.05
      else if tempo > 4.0 then custo_sem_desconto *. 0.15
      else 0.0
    in
    let total = custo_sem_desconto -. desconto in
    Printf.printf "%d;%.2f;%.2f;%.2f;%.2f;%.2f\n" id tempo custo_hora custo_sem_desconto desconto total
  ) servicos_filtrados

(* 4a. Descontos aplicados nas peças *)
let orcamento_desconto_items ids items servicos descontos =
  let servicos_filtrados = List.filter (fun (id, _, _, _, _, _) -> List.mem id ids) servicos in
  let categorias = List.flatten (List.map (fun (_, _, cats, _, _, _) -> cats) servicos_filtrados) in
  let categorias_unicas = List.sort_uniq String.compare categorias in
  let pecas = List.filter_map (fun cat -> encontrar_melhor_peca cat items descontos) categorias_unicas in
  List.iter (fun (id, _, marca, _, custo, preco, _) ->
    let desconto = try List.assoc marca descontos with Not_found -> 0.0 in
    let valor_desconto = preco *. desconto in
    Printf.printf "%d;%.2f;%.2f\n" id (desconto *. 100.0) valor_desconto
  ) pecas

  (**************            Orçamento            **********************)
 (* Função que gera o orçamento final baseado nos argumentos recebidos *)
let escrever_orcamento args =
  (* Lê o conteúdo completo do ficheiro database.pl *)
  let linhas = read_file "database.pl" in
  (* Carrega os dados de serviços, mecânicos, peças e descontos *)
  let servicos = carregar_servicos linhas in
  let mecanicos = carregar_mecanicos linhas in
  let items = carregar_items linhas in
  let descontos = carregar_descontos linhas in

  (* Abre o ficheiro de saída "orcamento.txt" para escrita *)
  let oc = open_out "orcamento.txt" in
  (* Variável mutável para acumular o total do orçamento *)
  let total = ref 0.0 in

  (* Função recursiva para processar os argumentos recebidos *)
  let rec process args =
    match args with
    | sid :: mid :: horas :: rest ->   (* Processa trios de argumentos: serviço, mecânico, horas *)
        let servico_id = int_of_string sid in
        let mecanico_id = int_of_string mid in
        let horas_real = float_of_string horas in

        (* Procura o serviço correspondente pelo ID *)
        let (id, nome_servico, categorias, num_mecs, tempo_default, preco_base) =
          List.find (fun (id, _, _, _, _, _) -> id = servico_id) servicos
        in

        (* Procura o nome do mecânico escolhido *)
        let (_, nome_mecanico, _) =
          List.find (fun (id, _, _) -> id = mecanico_id) mecanicos
        in

        (* ATENÇÃO: Para o cálculo, usa sempre o custo-hora do Ganâncio *)
        let custo_hora =
          let (_, _, custo) = List.find (fun (id, _, _) -> id = 1) mecanicos
          in custo
        in

        (* Procura a melhor peça disponível para as categorias do serviço *)
        let melhor_peca =
          List.fold_left (fun acc (id_item, nome, marca, tipo, custo, preco, quantidade) ->
            if List.mem tipo categorias then
              match acc with
              | None -> Some (nome, preco)
              | Some (_, preco_acc) -> if quantidade > 0 then Some (nome, preco) else acc
            else
              acc
          ) None items
        in

        (* Se encontrou peça, usa-a, senão assume "Sem peça" e preço 0 *)
        let peca_nome, peca_preco =
          match melhor_peca with
          | Some (nome, preco) -> (nome, preco)
          | None -> ("Sem peça", 0.0)
        in

        (* Calcula o custo de mão de obra com o custo do Ganâncio *)
        let custo_mao_obra = horas_real *. custo_hora in

        (* Cálculo do preço final do serviço *)
        let preco_final =
          if preco_base > 0.0 then preco_base +. custo_mao_obra +. peca_preco
          else custo_mao_obra +. peca_preco
        in

        (* Atualiza o valor total do orçamento *)
        total := !total +. preco_final;

        (* Escreve no ficheiro a informação do serviço, custo de mão de obra e peça utilizada *)
        Printf.fprintf oc "%s - %.2f€\n" nome_servico preco_final;
        Printf.fprintf oc "  (%d mecânico(s): %s @ %.2f€/h, %.2f horas)\n" num_mecs nome_mecanico custo_hora horas_real;
        Printf.fprintf oc "  Peça utilizada: %s (%.2f€)\n\n" peca_nome peca_preco;

        (* Continua com os restantes argumentos *)
        process rest
    | [] -> ()   (* Caso base: terminou a lista *)
    | _ -> failwith "Erro: argumentos devem vir em trios (servico_id, mecanico_id, horas)."
  in

  (* Inicia o processamento dos argumentos *)
  process args;

  (* Escreve o total final no ficheiro *)
  Printf.fprintf oc "TOTAL: %.2f€\n" !total;
  (* Fecha o ficheiro *)
  close_out oc

(***fim de orçamento**************)  
  
(* 4b. Preço fixo dos serviços *)
let orcamento_preco_fixo ids servicos =
  let servicos_filtrados = List.filter (fun (id, _, _, _, _, _) -> List.mem id ids) servicos in
  List.iter (fun (id, _, _, _, _, preco) ->
    Printf.printf "%d;%.2f\n" id preco
  ) servicos_filtrados

(**********************)
(*  Função principal  *)
(* ****************** *)

let () =
  (* Analisa os argumentos da linha de comando *)
  match Array.to_list Sys.argv with

  (* Comando: listar_items [modo] *)
  | _ :: "listar_items" :: modo :: _ ->
    (* Lê todas as linhas do ficheiro database.pl *)
    let linhas = read_file "database.pl" in
    (* Carrega todos os items *)
    let items = carregar_items linhas in
    (* Ordena os items por categoria e marca *)
    let ordenados = ordenar_items items in

    (* Função auxiliar: Agrupa os items por categoria *)
    let agrupar_por_categoria lista =
      List.fold_left (fun acc (id, nome, marca, tipo, custo, preco, quantidade) ->
        let lista_existente = try List.assoc tipo acc with Not_found -> [] in
        (tipo, lista_existente @ [(id, nome, marca, tipo, custo, preco, quantidade)]) :: (List.remove_assoc tipo acc)
      ) [] lista
    in

    (* Agrupa os items *)
    let agrupado = agrupar_por_categoria ordenados in

    (* Para cada categoria, imprime os items *)
    List.iter (fun (categoria, itens) ->
      Printf.printf "Categoria: %s\n" categoria;

      (* Ordena dentro da categoria conforme o modo *)
      let ordenados =
        match modo with
        | "quantidade" -> List.sort (fun (_,_,_,_,_,_,q1) (_,_,_,_,_,_,q2) -> compare q2 q1) itens
        | "preco" -> List.sort (fun (_,_,_,_,_,p1,_) (_,_,_,_,_,p2,_) -> compare p2 p1) itens
        | "custo" -> List.sort (fun (_,_,_,_,c1,_,_) (_,_,_,_,c2,_,_) -> compare c2 c1) itens
        | _ -> itens
      in

      (* Imprime conforme o modo escolhido *)
      List.iter (fun (_, nome, _, _, custo, preco, quantidade) ->
        match modo with
        | "quantidade" -> Printf.printf "  Preço: %.2f€ - %s\n" preco nome
        | "preco" -> Printf.printf "  Quantidade: %d - %s\n" quantidade nome
        | "custo" -> Printf.printf "  Nome: %s - Quantidade: %d - Preço: %.2f€\n" nome quantidade preco
        | _ -> Printf.printf "  %s\n" nome
      ) ordenados;

      (* Espaço entre categorias *)
      Printf.printf "\n"
    ) agrupado

  (* Comando: listar_servicos *)
  | _ :: "listar_servicos" :: _ ->
    let linhas = read_file "database.pl" in
    let servicos = carregar_servicos linhas in
    if servicos = [] then
      Printf.printf "Nenhum serviço encontrado.\n"
    else
      List.iter (fun (id, nome, categorias, _, _, _) ->
        Printf.printf "Serviço ID %d: %s\n" id nome;
        Printf.printf "  Categorias: %s\n\n" (String.concat ", " categorias)
      ) servicos

  (* Comando: listar_descontos *)
  | _ :: "listar_descontos" :: _ ->
    let linhas = read_file "database.pl" in
    let descontos = carregar_descontos linhas in
    if descontos = [] then
      Printf.printf "Nenhum desconto encontrado.\n"
    else
      List.iter (fun (marca, desconto) ->
        Printf.printf "Marca: %s, Desconto: %.2f€\n" marca (desconto *. 100.0)
      ) descontos

  (* Comando: listar_mecanicos *)
  | _ :: "listar_mecanicos" :: _ ->
    let linhas = read_file "database.pl" in
    let mecanicos = carregar_mecanicos linhas in
    if mecanicos = [] then
      Printf.printf "Nenhum mecânico encontrado.\n"
    else
      List.iter (fun (_, nome, custo) ->
        Printf.printf "Nome: %s, Custo-hora: %.2f€\n" nome custo
      ) mecanicos

  (* Comando: gerar_orcamento [args] *)
  | _ :: "gerar_orcamento" :: args ->
    (* Chama a função de geração de orçamento com os argumentos *)
    escrever_orcamento args

  (* Comando: orcamento_items id1,id2,... *)
  | _ :: "orcamento_items" :: ids ->
    let linhas = read_file "database.pl" in
    let items = carregar_items linhas in
    let servicos = carregar_servicos linhas in
    let descontos = carregar_descontos linhas in
    let ids = List.flatten (List.map (fun s -> List.map int_of_string (Str.split (Str.regexp ",") s)) ids) in
    orcamento_items ids items servicos descontos

  (* Comando: orcamento_mecanico id1,id2,... *)
  | _ :: "orcamento_mecanico" :: ids ->
    let linhas = read_file "database.pl" in
    let servicos = carregar_servicos linhas in
    let mecanicos = carregar_mecanicos linhas in
    let ids = List.flatten (List.map (fun s -> List.map int_of_string (Str.split (Str.regexp ",") s)) ids) in
    orcamento_mecanico ids servicos mecanicos

  (* Comando: orcamento_desconto_items id1,id2,... *)
  | _ :: "orcamento_desconto_items" :: ids ->
    let linhas = read_file "database.pl" in
    let items = carregar_items linhas in
    let servicos = carregar_servicos linhas in
    let descontos = carregar_descontos linhas in
    let ids = List.flatten (List.map (fun s -> List.map int_of_string (Str.split (Str.regexp ",") s)) ids) in
    orcamento_desconto_items ids items servicos descontos

  (* Comando: orcamento_preco_fixo id1,id2,... *)
  | _ :: "orcamento_preco_fixo" :: ids ->
    let linhas = read_file "database.pl" in
    let servicos = carregar_servicos linhas in
    let ids = List.flatten (List.map (fun s -> List.map int_of_string (Str.split (Str.regexp ",") s)) ids) in
    orcamento_preco_fixo ids servicos

  (* Caso nenhum comando válido seja fornecido *)
  | _ ->
    Printf.printf "Comandos disponíveis:\n";
    Printf.printf "  listar_items\n";
    Printf.printf "  listar_servicos\n";
    Printf.printf "  listar_descontos\n";
    Printf.printf "  listar_mecanicos\n";
    Printf.printf "  orcamento_items id1,id2,...\n";
    Printf.printf "  orcamento_mecanico id1,id2,...\n";
    Printf.printf "  orcamento_desconto_items id1,id2,...\n";
    Printf.printf "  orcamento_preco_fixo id1,id2,...\n"
