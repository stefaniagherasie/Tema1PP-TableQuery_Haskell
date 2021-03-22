-- Tema1PP - GHERASIE STEFANIA 323CB

module Query where

import Data.List
import UserInfo
import Rating
import Movie

type Column = String
type TableSchema = [Column]
type Field = String
type Entry = [Field]

data Table = Table TableSchema [Entry]

type ColSeparator = Char
type LnSeparator = Char

user_info = read_table '|' '\n' user_info_str
rating = read_table ' ' '\n' rating_str
movie = read_table '|' '\n' movie_str



-- READ TABLE --

read_table :: ColSeparator -> LnSeparator -> String -> Table
read_table cl ln str = Table (head table) (tail table)
          where table = init $ map (splitBy cl) (splitBy ln str)


-- Despartirea unui String dupa un delimitator
splitBy :: Char -> String -> [String]
splitBy c = foldr op [[]] 
              where op x acc
                      | x /= c = (x:(head acc)):(tail acc)
                      | otherwise = []:(acc)



-- SHOW TABLE --

instance Show Table where
  show (Table h entries) = line ++ (showLine h len) ++ line ++ (showEntries entries len) ++ line
                          where { 
                                  len = reverse (maxLen (Table h entries) (length h));
                                  -- Se formeaza linia de caractere "-"
                                  line = flip replicate '-' (sum len + length h + 1) ++ "\n" }


-- Obtine o lista cu lungimea elementelor de pe coloanele cu un indice dat
columnLen :: [Entry] -> Int -> [Int]
columnLen [] _ = []
columnLen (x:xs) index = length (x!!index) : (columnLen xs index)

-- Calculeaza maximul dimensiunilor de pe coloana "index"
maxColumnLen :: Table -> Int-> Int
maxColumnLen (Table h entries) index = maximum $ length (h!!index) : (columnLen entries index)

-- Obtine o lista cu dimensiunile maxime de pe fiecare coloana
maxLen :: Table -> Int -> [Int]
maxLen table 1 = [maxColumnLen table 0]
maxLen table index = maxColumnLen table (index - 1) : (maxLen table (index - 1))

-- Returneaza Entry-ul de pe pozitia index
getEntry :: Table -> Int -> Entry
getEntry (Table header entries) index = entries!!index

-- Afiseaza un rand din tabel
showLine :: [String] -> [Int] -> String
showLine [] _ = "|\n"
showLine (x:xs) (y:ys) = "|" ++ x ++ (flip replicate ' ' (y - length x)) ++ (showLine xs ys)

-- Afiseaza o intrarile din tabel
showEntries :: [Entry] -> [Int] -> String
showEntries [] _ = ""
showEntries (x:xs) len = (showLine x len) ++ (showEntries xs len)



-- SELECT --

selectTable :: [String] -> Query -> Table
selectTable fields (Atom (Table h entries)) = Table newH newEntries
                            where { 
                                    indices = getIndices fields h;
                                    -- Se formeaza un nou header si noi intrari.
                                    newH = selectColumn h indices;
                                    newEntries = map (\x -> selectColumn x indices) entries }
-- Se evalueaza Query-ul si apoi se selecteaza coloanele
selectTable fields query = selectTable fields (Atom (eval query))



-- SELECT LIMIT --

selectLimit :: [String] -> Integer -> Query -> Table
selectLimit fields n (Atom (Table h entries)) = Table newH newEntries
                            where { 
                                    indices = getIndices fields h;
                                    -- Se formeaza un nou header si noi intrari.
                                    newH = selectColumn h indices;
                                    newEntries = map (\x -> selectColumn x indices) 
                                                (take (fromIntegral n) entries) }
-- Se evalueaza Query-ul si apoi se selecteaza coloanele
selectLimit fields n query = selectLimit fields n (Atom (eval query))


-- Gaseste indicii coloanelor care trebuie selectate
getIndices :: [String] -> TableSchema -> [Int]
getIndices [] h = []
getIndices (x:xs) h = (elemIndices x h) ++ (getIndices xs h)


-- Selecteaza coloanele dintr-o linie care corespund indicilor
selectColumn :: Entry -> [Int] -> Entry
selectColumn _ [] = []
selectColumn line (x:xs) = (line!!x) : (selectColumn line xs) 



-- FILTER --

data FilterCondition = Lt Field Integer | Eq Field String | In Field [String] | Not FilterCondition

-- Aplica filtrul pe un Query apeland getFilter
filterCond :: FilterCondition -> Query -> Table

filterCond cond (Atom (Table h entries)) = Table h (filter (getFilter cond h) entries)
filterCond cond query = filterCond cond (Atom (eval query))


-- Obtine o functie care va fi aplicata pentru filtrarea tabelei
getFilter :: FilterCondition -> TableSchema -> (Entry -> Bool)

getFilter (Lt field n) h = (\x -> (read (x!!index) :: Integer) < n)
                                where [index] = elemIndices field h
getFilter (Eq field str) h = (\x -> (x!!index) == str)
                                where [index] = elemIndices field h
getFilter (In field list) h = (\x -> elem (x!!index) list)
                                where [index] = elemIndices field h
getFilter (Not cond) h = (\x -> negateCond cond x h)


-- Neaga conditiile din FilterCondition
negateCond :: FilterCondition -> Entry -> TableSchema -> Bool 

negateCond (Lt field n) entry h = (read (entry!!index) :: Integer) >= n
                                where [index] = elemIndices field h
negateCond (Eq field str) entry h = (entry!!index) /= str
                                where [index] = elemIndices field h
negateCond (In field list) entry h = not $ elem (entry!!index) list
                                where [index] = elemIndices field h
negateCond (Not cond) entry h = negateCond cond entry h



-- OR TABLE --

-- Formeaza un tabel prin concatenarea Entry-urilor celor 2 tabele date.
orTable :: Table -> Table -> Table
orTable (Table h1 e1) (Table h2 e2) = Table h1 (e1 ++ e2)



-- EVAL TABLE --

data Query = Filter FilterCondition Query |  
             Select [String] Query |
             SelectLimit [String] Integer Query |
             Cosine Query |
             Query :|| Query |
             Atom Table


-- Evalueaza Query-ul si returneaza tabele
eval :: Query -> Table
eval (Atom table) = table
eval (Select fields query) = selectTable fields query
eval (SelectLimit fields n query) = selectLimit fields n query
eval (Filter (Lt field n) query) = filterCond (Lt field n) query
eval (Filter (Eq field str) query) = filterCond (Eq field str) query 
eval (Filter (In field list) query) = filterCond (In field list) query 
eval (Filter (Not cond) query) = filterCond (Not cond) query
eval (query1 :|| query2) = orTable (eval query1) (eval query2)



-- EVAL FUNCTIONS --

-- Obtine zona cautata, filtreaza persoanele cu aceeasi zona, scoate din tabel persoana
-- cu id-ul dat si apoi selecteaza coloanele "user_id" si "occupation".
same_zone :: String -> Query
same_zone id =  Atom $ eval $ Select ["user_id", "occupation"] $ Filter (Not (Eq "user_id" id)) $
                Filter (Eq "zone" zone) $ Atom user_info
                  where zone = (getEntry (eval $ Filter (Eq "user_id" id) $ Atom user_info) 0)!!4


-- Filtreaza tabela dupa sex masculin, obtine persoanele cu varsta in intervalul dat
-- si selecteaza coloanele "occupation" si "zone".
male_within_age :: Integer -> Integer -> Query
male_within_age x y =   Atom $ eval $ Select ["occupation", "zone"] $ 
                        Filter (Not (Eq "age" (show x))) $ Filter (Not (Lt "age" x)) $ 
                        Filter (Lt "age" y) $ Filter (Eq "sex" "M") $ Atom user_info


-- Filtreaza tabelul dupa varsta mai mare ca n, apoi dupa ocupatiile si zonele cerute
-- si selecteaza campul "user_id".
mixed :: [String] -> [String] -> Integer -> Query
mixed zones occups n =  Atom $ eval $ Select ["user_id"] $ Filter (In "occupation" occups) $
                        Filter (In "zone" zones) $ Filter (Lt "age" n) $ Atom user_info