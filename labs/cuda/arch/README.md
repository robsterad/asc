# Arhitectura CUDA

## Recapitulare

Înainte să vă apucați de acest laborator vă rugăm să verificați că sunteți
familiari cu dezvoltarea folosind cluster-ul/unitatea personală pe baza
surselor din acest repo.

Recitiți [descrierea infrastructurii](../README.md) în acest sens.

## Profiling

**Atenție**! `ncu` poate fi utilizat doar pe partiția `ucsx`, **NU** și pe `xl`.

[ncu] este utilitarul de care vom dispune.

```bash
make run RUN_CMD='ncu --print-details all ./$(EXEC)'
```

Pentru a salva rezultatul profiling-ului într-un fișier rulați următoarea
comandă.

```bash
[prenume.numeID@fep8 proj]$ make run RUN_CMD='ncu -o profile ./$(EXEC)'
```

În acest exemplu `profile` și rezultatul vor fi salvate în fișierul
`profile.ncu-rep`. Apoi, pentru a încărca și afișa în consolă profile-ul se
folosește flagul `--import`.

```bash
[prenume.numeID@fep8 proj]$ make run RUN_CMD='ncu --import profile.ncu-rep'
```

### Explicații

De ce comanda de rulare este așa compilcată?
Afișați comanda de `sbatch` din spatele `make run` prin parametrul `-n`.

```bash
[prenume.numeID@fep8 proj]$ make run RUN_CMD='ncu --print-details all ./$(EXEC)' -n
```

O particularitate a `ncu` este faptul că utilizează un fișier `lock` pe care-l
scrie pe disk. Fișierul se numește `nsight-compute-lock`. În mod implicit,
acest fișier este plasat în `/tmp/`. Deoarece toate conturile partajează
`/tmp` și numele fișierului este unul static (`nsight-compute-lock`), a fost
definită variabila de mediu `TMPDIR=$HOME` în comanda de rulare.

Astfel, în urma rulării comenzilor pentru profiling, veți găsi în directorul
vostru `$HOME` de pe `fep8.grid.pub.ro` fișierul `nsight-compute-lock`. Îl
puteți șterge fără nicio problemă.

## Exerciții

0. Rulați exemplele din [tutorials](tutorials/).
   > *Notă*. Analizați comenzile `sbatch` rulate de `Makefile` pentru a
     înțelege care este modul de operare/execuție în cluster.
1. Rezolvați problemele din [exercises](exercises/) urmărind `TODO`-urile.
    1. Pentru [benchmark](exercises/benchmark/)-ing încercați să măsurați
      performanța maximă a unității GPU, înregistrând numărul de GFLOPS.
        * Masurați timpul petrecut în kernel.
          > *Indiciu.* Folositi evenimente CUDA.
        * Realizați un profiling pentru funcțiile implementate folosind
        utilitarul `ncu`.
    2. Pentru [matrix_multiply](exercises/matrix_multiply/):
        * Completați funcția `matrix_multiply_simple` care va realiza
          înmulțirea a două matrice primite prin parametrii.
        * Completați funcția `matrix_multiply` care va realiza o înmulțire
          optimizată a două matrice, folosind Blocked Matrix Multiplication.
            > *Indiciu.* Folosiți directiva `__shared__` pentru a aloca memorie
              partajată între thread-uri. Pentru sincronizarea thread-urilor
              folosiți funcția `__syncthreads`.
        * Măsurați timpul petrecut în kernel
            > *Indiciu.* Folosiți evenimente CUDA.
        * Realizați un profiling pentru funcțiile implementate folosind
        utilitarul `ncu`.

[ncu]: https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html#quickstart
