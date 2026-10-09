Nume: Radulescu Robert-Stefan

Grupă: 331CC

# Tema ASC - Implementarea în CUDA a arborelui Merkle și a algoritmului de consens Proof of Work din cadrul Bitcoin

Organizare
-

Pentru merkle root, decizia de a folosi cate un thread per operatie este justificata de numarul mic de tranzactii.

Pentru functia de gasire nonce, ideea de baza este sa paralelizam cautarile, folosind functii atomice specifice CUDA pentru 
comunicarea intre ele la gasirea unui nonce potrivit.

Implementare
-

Pentru constructia merkle root am ales sa folosesc cate un thread pentru hashingul fiecarei tranzactii initiale.
In functia de host, dupa hashingul initial, la fiecare pas lansez threaduri care sa combine hash-ul lor cu cel vecin,
si sa aplice hash pe rezultat. Am decis sa fac aceasta coordonare din functia de host, caci la fiecare pas injumatatim
numarul de operatii, deci se termina rapid si nu se merita cresterea complexitatii codului prin coordonarea threadurilor 
intre ele.

Pentru gasirea nonce-ului, pentru a scapa de overhead-ul introdus de GPU scheduling - in contextul numarului mare de nonce-uri
care trebuie verificate, am ales sa lansez un numar cat mai mare de blocuri, cat sa folosesc toata capacitatea placii video, iar
fiecare thread sa calculeze propriile hash-uri cu nonce-urile threadId, threadId + blockDim * blockSize, threadId + 2 * blockDim*blockSize, ... pana la max_nonce. La fiecare hash pe care un thread urmeaza sa il verifice, se asigura intai ca 
alt thread nu a gasit un nonce valid.
Ma folosesc de structura SHA256_CTX si functia apply_sha256_from_ctx date suport pentru a nu concatena manual continutul blocului 
curent cu fiecare nonce de incercat.