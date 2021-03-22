# Tema1PP-TableQuery_Haskell
[Tema1 Paradigme de Programare (2019-2020, seria CB)] 

Obiectivul temei este implementarea în Haskell a unei biblioteci simple pentru reprezentarea,
citirea și interogarea de tabele.

RULARE:
- make run_tests - pentru a rula toate testele
- make run_shell  [set]  [subset] - pentru a testa manual,  alegem setul de test (specificat în Main.hs) și subtestul dorit pentru a vedea output-ul


Citirea unui tabel se face dintr-un String. Pentru a citi un tabel, s-a implementat funcția
read_table având următoarea semnătură:
- read_table :: ColSeparator -> LnSeparator -> String -> Table

Query-urile se evaluează la tabele existente, dar și la altele noi, care sunt construite prin:
selectarea anumitor coloane dintr-un tabel sau selectarea unui număr limitat de Entry-uri;
filtrarea de Entry-uri, combinarea Entry-uri din mai multe tabele, cosine-similarity, care va fi
discutat în detaliu mai jos.
- Atom Table - reprezintă exact tabelul primit ca parametru.
- Select [Field] Query. Constructorul primește o lista de coloane și un query q.
Evaluarea acestuia selectează doar coloanele specificate în tabelul la care se evaluează q.
- SelectLimit [Field] Integer Query - la fel ca Select, însă selectează un
număr specificat de Entry-uri. 
- Filter FilterCondition Query - reprezinta filtrarea Entry-urilor pe baza unei
valori de tip FilterCondition. Condițiile de filtrare sunt reprezentate de următorul tip:
  
  data FilterCondition = Lt Field Integer |
                            Eq Field String |
                            In Field [String] |
                            Not FilterCondition                   
- Query :|| Query - reprezintă reuniunea Entry-urilor din evaluarea a două query-uri
diferite


