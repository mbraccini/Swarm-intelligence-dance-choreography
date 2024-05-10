import json
import math

import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import sys
import numpy as np

def addIfKeyDoesNotExist(mydict, key, value):
    if key in mydict:
        mydict.get(key).append(value)
    else:
        mydict[key] = [value]

def analyze(f):
    notesPerBar = {}
    volumesPerBar= {}
    
    #### ANALIZZA NOTES
    for n in f['NOTES']:
        nota = n['midiNote']
        battutaInizio = n['startBar']
        battutaFine= n['endBar']
        velocity = n['velocity']
        #if battutaInizio in notesPerBar:
        #    notesPerBar.get(battutaInizio).append(nota)
        #else:
        #    notesPerBar[battutaInizio] = [nota]
    
        addIfKeyDoesNotExist(notesPerBar, battutaInizio, nota)    
        addIfKeyDoesNotExist(volumesPerBar, battutaInizio, velocity)    
    
        if battutaInizio != battutaFine:
            addIfKeyDoesNotExist(notesPerBar, battutaFine, nota) 
            addIfKeyDoesNotExist(volumesPerBar, battutaInizio, velocity)    
        
            #if battutaFine in notesPerBar:
            #    notesPerBar.get(battutaFine).append(nota)
            #else:
            #    notesPerBar[battutaFine] = [nota]
        ### VOLUME
        print(f"Nota: {nota}, battutaInizio: {battutaInizio}, battutaFine: {battutaFine}, velocity: {velocity}")
    #### ANALIZZA BARS
    durationPerBar = {}
    
    for n in f['BARS']:
        indexBattuta = n['index']
        durataBattutaInSecondi = n['durationTime']
    
        durationPerBar[indexBattuta] = durataBattutaInSecondi
        #addIfKeyDoesNotExist(durationPerBar, indexBattuta, durataBattutaInSecondi)    
    
            #if battutaFine in notesPerBar:
            #    notesPerBar.get(battutaFine).append(nota)
            #else:
            #    notesPerBar[battutaFine] = [nota]
        ### VOLUME
        print(f"index: {indexBattuta}, durataBattutaInSecondi: {durataBattutaInSecondi}")

    print(volumesPerBar)

    print(volumesPerBar[0])
    return notesPerBar, volumesPerBar, durationPerBar
# Initialize an empty res_dictionary to store the results
# Inizializza il dizionario risultato

def plotHist(data_dict, path, name):
    # Example dictionary with lists
    #data_dict = {
    #    'list1': [1, 2, 3, 4, 5],
    #    'list2': [10, 20, 30, 40, 50],
        # Add more lists here...
    #}

    # Create histograms and save as images
    for key, value in data_dict.items():
        plt.hist(value, bins=10, alpha=0.5, color='blue')
        plt.xlim(0,127)
        plt.title(f'{name} for Bar #{key}')
        plt.xlabel('Values')
        plt.ylabel('Frequency')
        plt.savefig(f'{path}{key}_{name}.png')
        plt.close()

    # Combine images into a single PDF
    pdf_filename = (f'{path}histograms_{name}.pdf')
    c = canvas.Canvas(pdf_filename, pagesize=letter)
    for key in data_dict:
        c.drawImage(f'{path}{key}_{name}.png', 100, 500, width=400, height=300)
        c.showPage()
    c.save()

    print(f"PDF with histograms saved as '{pdf_filename}'")

def save_list_to_file(my_list, filename):
    with open(filename, 'w') as file:
        for item in my_list:
            file.write(f"{item}\n")
    print(f"Lista salvata nel file '{filename}'")



def compute_entropy(numbers):
    # Calcola la frequenza di ciascun numero nella lista
    freq_dict = {}
    total_count = len(numbers)
    for num in numbers:
        if num in freq_dict:
            freq_dict[num] += 1
        else:
            freq_dict[num] = 1

    # Calcola l'entropia
    entropy = 0
    for count in freq_dict.values():
        probability = count / total_count
        entropy -= probability * math.log2(probability)

    return entropy    
    
fileJSON = sys.argv[1]
#fileJSON="/Volumes/BX500/git/dancing-robots-netlogo/code/MIDI/Fur_Elise_Easy_Piano.midoutput.json"
# Carica il contenuto del file JSON
with open(fileJSON, 'r') as file:
    f = json.load(file)    
    

# Esempio di utilizzo
#my_list = [1, 2, 3, 4, 5]
#save_list_to_file(my_list, 'lista_numeri.txt')
# Esempio di utilizzo
#lista_numeri = [2, 2, 3, 3,4,4,6,6]
#entropia = compute_entropy(lista_numeri)
#print(f"L'entropia della lista è: {entropia:.4f}")

notes, volumes, barDurations=analyze(f)    

print(notes)
print(volumes)

# MEAN OF VOLUMES
mean_volumes = [np.mean(value) for key, value in volumes.items()]
maxVolume = max(mean_volumes)
normalizedMeanVolumes = [numero / maxVolume for numero in mean_volumes]

save_list_to_file(normalizedMeanVolumes, (f'{fileJSON}_meanVolumes.txt'))

print(mean_volumes)


# ENTROPIES
notes_entropies = [compute_entropy(value) for key, value in notes.items()]



maxEntropy = max(notes_entropies)
normalizedEntropy = [numero / maxEntropy for numero in notes_entropies]
print(normalizedEntropy)
#print(barDurationsList)
save_list_to_file(normalizedEntropy, (f'{fileJSON}_entropies.txt'))

# BARS DURATIONS
barDurationsList = [value for key, value in barDurations.items()]
print(notes_entropies)
save_list_to_file(barDurationsList, (f'{fileJSON}_barDurations.txt'))

#plotHist(notes,"imgs/","notes")
#plotHist(volumes,"imgs/","volumes")



