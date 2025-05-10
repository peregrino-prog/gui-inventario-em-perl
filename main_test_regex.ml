(* main_test_regex.ml - Testador específico para ITEM, MECANICO e DESCONTO *)
open Str


(* Regex comprovada que funciona para serviços *)
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

(* Função principal de teste *)
let test_line line =
  let line = String.trim line in
  if line = "" || line.[0] = '%' then () else
  
  Printf.printf "\nLinha: <<%s>>\n" line;
  
  let test_regex regex name groups =
    if Str.string_match regex line 0 then (
      Printf.printf "✔ %s\n" name;
      for i = 1 to groups do
        try Printf.printf "  Grupo %d: %s\n" i (Str.matched_group i line)
        with _ -> ()
      done;
      true
    ) else false
  in
  if not (test_regex regex_servico "ITEM" 6) then
  if not (test_regex regex_item "ITEM" 7) then
  if not (test_regex regex_mecanico "MECANICO" 3) then
  if not (test_regex regex_desconto "DESCONTO_MARCA" 2) then
  if not (test_regex regex_desconto_mao "DESCONTO_MAO_OBRA" 5) then
  Printf.printf "✖ Padrão não reconhecido\n"

(* Ponto de entrada *)
let () =
  let db_file = "database.pl" in
  Printf.printf "=== TESTANDO database.pl ===\n";
  
  try
    let ch = open_in db_file in
    let rec process () =
      try
        test_line (input_line ch);
        process ()
      with End_of_file -> close_in ch
    in
    process ();
    Printf.printf "\n=== FIM DOS TESTES ===\n"
  with Sys_error _ ->
    Printf.eprintf "ERRO: Arquivo '%s' não encontrado!\n" db_file