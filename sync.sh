#!/bin/bash

# Script di sincronizzazione SEMPLIFICATO per Mac
# Copia tutto nella cartella Experts di MT5

FOLDER="1NB"
printf " Syncing $FOLDER to MT5... \n\n"

# Percorsi
PROJECT_DIR="$(pwd)"
MT5_EXPERTS_BASE="/Users/$USER/metatrader_master/drive_c/MetaTrader_Master/MQL5/Experts"
MT5_EXPERTS="$MT5_EXPERTS_BASE/$FOLDER"

printf " Checking paths... \n\n"
printf " MT5_EXPERTS_BASE: $MT5_EXPERTS_BASE\n\n"
printf " TARGET_FOLDER: $MT5_EXPERTS\n\n"

# Verifica che la cartella base Experts esista
if [ ! -d "$MT5_EXPERTS_BASE" ]; then
    printf "\n \r MT5 Experts base folder not found at: $MT5_EXPERTS_BASE"
    exit 1
fi

# Crea la cartella $FOLDER se non esiste
if [ ! -d "$MT5_EXPERTS" ]; then
    printf " Creating $FOLDER folder..."
    mkdir -p "$MT5_EXPERTS"
    printf " Folder created: $MT5_EXPERTS"
else
    printf " $FOLDER folder already exists"
fi

# Copia TUTTI i file .mq5 e .mqh nella cartella $FOLDER

printf " Copying all files to $FOLDER folder...$PROJECT_DIR\n\n"
cp "$PROJECT_DIR"/*.mq5 "$MT5_EXPERTS/" 2>/dev/null || printf "️No .mq5 files found"
cp "$PROJECT_DIR"/*.mqh "$MT5_EXPERTS/" 2>/dev/null || printf "️No .mqh files found"

# Mostra i file copiati
printf " Files in $FOLDER folder:\n\n"
ls -la "$MT5_EXPERTS"

printf "\n\nSync completed!"
printf " Now go to MT5 and compile"

# Opzionale: apri MT5 automaticamente
# open -a "MetaTrader 5"/Users/barno/metatrader_master/drive_c/MetaTrader_Master