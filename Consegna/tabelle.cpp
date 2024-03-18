#include <cstdio>
#include <iostream>
#include "dependencies/include/libpq-fe.h"
#define PG_HOST "localhost" // oppure " localhost " o " postgresql "
#define PG_USER "postgres" // il vostro nome utente
#define PG_DB "PizzeriaDB" // il nome del database
#define PG_PASS "dajeRoma22" // la vostra password
#define PG_PORT 5432
using namespace std;

PGresult* execute(PGconn* conn, const char* query) {
    PGresult* res = PQexec(conn, query);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        cout << " Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
        PQclear(res);
        exit(1);
    }

    return res;
}

void printLine(int campi, int* maxChar) {
    for (int j = 0; j < campi; ++j) {
        cout << '+';
        for (int k = 0; k < maxChar[j] + 2; ++k)
            cout << '-';
    }
    cout << "+\n";
}
void printQuery(PGresult* res) {
    // Preparazione dati
    const int tuple = PQntuples(res), campi = PQnfields(res);
    string v[tuple + 1][campi];

    for (int i = 0; i < campi; ++i) {
        string s = PQfname(res, i);
        v[0][i] = s;
    }
    for (int i = 0; i < tuple; ++i)
        for (int j = 0; j < campi; ++j) {
            if (string(PQgetvalue(res, i, j)) == "t" || string(PQgetvalue(res, i, j)) == "f")
                if (string(PQgetvalue(res, i, j)) == "t")
                    v[i + 1][j] = "si";
                else
                    v[i + 1][j] = "no";
            else
                v[i + 1][j] = PQgetvalue(res, i, j);
        }

    int maxChar[campi];
    for (int i = 0; i < campi; ++i)
        maxChar[i] = 0;

    for (int i = 0; i < campi; ++i) {
        for (int j = 0; j < tuple + 1; ++j) {
            int size = v[j][i].size();
            maxChar[i] = size > maxChar[i] ? size : maxChar[i];
        }
    }

    // Stampa effettiva delle tuple
    printLine(campi, maxChar);
    for (int j = 0; j < campi; ++j) {
        cout << "| ";
        cout << v[0][j];
        for (int k = 0; k < maxChar[j] - v[0][j].size() + 1; ++k)
            cout << ' ';
        if (j == campi - 1)
            cout << "|";
    }
    cout << endl;
    printLine(campi, maxChar);

    for (int i = 1; i < tuple + 1; ++i) {
        for (int j = 0; j < campi; ++j) {
            cout << "| ";
            cout << v[i][j];
            for (int k = 0; k < maxChar[j] - v[i][j].size() + 1; ++k)
                cout << ' ';
            if (j == campi - 1)
                cout << "|";
        }
        cout << endl;
    }
    printLine(campi, maxChar);
}

char* chooseParam(PGconn* conn, const char* query, const char* table) {
    PGresult* res = execute(conn, query);
    printQuery(res);

    const int tuple = PQntuples(res), campi = PQnfields(res);
    int val;
    cout << "Inserisci il numero del " << table << " scelto: ";
    cin >> val;
    while (val <= 0 || val > tuple) {
        cout << "Valore non valido\n";
        cout << "Inserisci il numero del " << table << " scelto: ";
        cin >> val;
    }
    return PQgetvalue(res, val - 1, 0);
}



int main (int argc, char** argv) {

    char conninfo [250];
    sprintf(conninfo , "user=%s password=%s dbname=%s host=%s port=%d",
    PG_USER, PG_PASS, PG_DB, PG_HOST, PG_PORT);
    PGconn* conn = PQconnectdb(conninfo);
    
    if (PQstatus(conn)!=CONNECTION_OK) {
        cout<<"Errore di connessione "<<PQerrorMessage(conn);               
        exit(1);
    }
    else {
        cout<<"Connessione avvenuta \n";   
    }
    

    const char* query[9] = {
        "SELECT DISTINCT Pizza.NomePizza \
        FROM Pizza \
        JOIN Contiene ON Pizza.NomePizza = Contiene.NomePizza \
        JOIN Ingrediente ON Contiene.NomeIngrediente = Ingrediente.NomeIngrediente \
        WHERE Ingrediente.Disponibile = true \
        GROUP BY Pizza.NomePizza \
        HAVING COUNT(*) = ( \
        SELECT COUNT(*) \
        FROM Contiene AS C\
        WHERE C.NomePizza = Pizza.NomePizza);",


        "SELECT IdCameriere,Sesso, Nome, Cognome, NumeroTavoliServiti \
        FROM ( \
        SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(Tavolo.NumeroTavolo) AS NumeroTavoliServiti, 'M' AS Sesso \
        FROM Cameriere \
        JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere \
        WHERE Cameriere.Sesso = 'M' \
        GROUP BY Cameriere.IdCameriere \
        UNION ALL \
        SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(Tavolo.NumeroTavolo) AS NumeroTavoliServiti, 'F' AS Sesso \
        FROM Cameriere \
        JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere \
        WHERE Cameriere.Sesso = 'F' \
        GROUP BY Cameriere.IdCameriere \
        ) AS subquery \
        ORDER BY NumeroTavoliServiti DESC \
        LIMIT 2;",


        "SELECT Cliente.Mail, Cliente.Nome, Cliente.Cognome, SUM(Pizza.Prezzo * Appartiene.quantita) AS TotaleSpeso \
        FROM Cliente \
        JOIN Ordinazione ON Cliente.Mail = Ordinazione.Mail_Cliente \
        JOIN Appartiene ON Ordinazione.IdOrdinazione = Appartiene.IdOrdinazione \
        JOIN Pizza ON Appartiene.NomePizza = Pizza.NomePizza \
        GROUP BY Cliente.Mail \
        ORDER BY TotaleSpeso DESC \
        LIMIT 5;",

        
        "SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(*) as NumeroPrenotazioni \
        FROM Cameriere \
        JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere \
        JOIN Prenota ON Tavolo.NumeroTavolo = Prenota.NumeroTavolo \
        GROUP BY Cameriere.IdCameriere \
        HAVING COUNT(*) > 5 \
        ORDER BY NumeroPrenotazioni ASC;", 

        "SELECT C.IdCuoco, C.Nome, C.Cognome, SUM(A.quantita) AS NumeroPizza \
        FROM Cuoco C \
        JOIN Ordinazione O ON C.IdCuoco = O.Cuoco \
        JOIN Appartiene A ON O.IdOrdinazione = A.IdOrdinazione \
        GROUP BY C.IdCuoco \
        HAVING SUM(A.quantita) > 60 \
        ORDER BY NumeroPizza DESC;",


        "SELECT Cliente.Mail, Cliente.Nome, Cliente.Cognome, Tessera.Punti \
        FROM Cliente \
        JOIN Tessera ON Cliente.Mail = Tessera.Cliente \
        ORDER BY Tessera.Punti DESC \
        LIMIT 5;",


        "SELECT Ingrediente.NomeIngrediente, \
        CASE WHEN Ingrediente.Surgelato THEN 'si' ELSE 'no' END AS Surgelato \
        FROM Pizza \
        JOIN Contiene ON Pizza.NomePizza = Contiene.NomePizza \
        JOIN Ingrediente ON Contiene.NomeIngrediente = Ingrediente.NomeIngrediente \
        WHERE Pizza.NomePizza = '%s';",

        "SELECT \
        CASE \
        WHEN EXISTS ( \
        SELECT 1 \
        FROM Prenota T \
        WHERE O.OraOrdinazione = T.Ora AND O.DataOrdinazione = T.DataP AND O.Mail_Cliente = T.Mail_Cliente \
        ) THEN 'Ristorante' \
        ELSE 'Asporto' \
        END AS Modalita, \
        COUNT(*) AS Quantita \
        FROM Ordinazione O \
        JOIN Cliente C ON O.Mail_Cliente = C.Mail \
        GROUP BY Modalita;",

        "SELECT SUM(OrdinazioneImporto.ImportoTotale) AS RicavoComplessivo \
        FROM ( \
        SELECT O.IdOrdinazione, SUM(P.Prezzo * AO.quantita) AS ImportoTotale \
        FROM Ordinazione AS O \
        JOIN Appartiene AS AO ON O.IdOrdinazione = AO.IdOrdinazione \
        JOIN Pizza AS P ON AO.NomePizza = P.NomePizza \
        WHERE EXTRACT(YEAR FROM O.DataOrdinazione) = 2022 \
        GROUP BY O.IdOrdinazione \
        ) AS OrdinazioneImporto;"

    };

    while (true) {
        cout << endl;
        cout << "1. Restituire il nome di tutte le pizze che possono essere preparate \n";
        cout << "   in base agli ingredienti disponibili\n";
        cout << "2. Restituire il cameriere e la cameriera con il massimo \n";
        cout << "   numero di tavoli assegnati\n";
        cout << "3. Restituire i primi 5 clienti che hanno speso in totale \n";
        cout << "   piu soldi nel ristorante\n";
        cout << "4. Restituire il nome, cognome e ID dei camerieri che hanno gestito piu' di 5 prenotazioni\n";
        cout << "5. Trovare i cuochi che hanno preparato piu' di 60 pizze\n";
        cout << "6. Ottenere i 5 clienti con piu' punti nella tessera\n";
        cout << "7. Restituire gli ingredienti presenti e se sono surgelati di una determinata pizza\n";
        cout << "   (NB: mettere la prima lettera maiuscola alla pizza scelta)\n";
        cout << "8. Determinare il numero di clienti che hanno consumato per asporto o al ristorante\n";
        cout << "9. Mostrare il ricavo complessivo nell'anno 2022\n";


        cout << "Query da eseguire (0 per uscire): ";
        int q = 0;
        cin >> q;
        while (q < 0 || q > 9) {
            cout << "Le query vanno da 1 a 9...\n";
            cout << "Query da eseguire (0 per uscire): ";
            cin >> q;
        }

        if (q == 0) break;
        char queryTemp[1500];

        int i = 0;
        switch (q) {
        
        case 7:
            char pizza[30];
            cout << "Inserisci il nome della pizza: ";
            cin >> pizza;
            sprintf(queryTemp, query[6], pizza);
            printQuery(execute(conn, queryTemp));
            break;

        default:
            printQuery(execute(conn, query[q - 1]));
            break;
        }



        system("pause");
    }




    PQfinish(conn);
    
    return 0;
}

