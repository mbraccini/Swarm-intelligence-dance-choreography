import mido
import json
import math
from collections import namedtuple
import sys

#for i in range(1, len(sys.argv)):
#    print('argument:', i, 'value:', sys.argv[i])
    
midFilename = sys.argv[1]
print(midFilename)
mid = mido.MidiFile(midFilename)

#exit()
#mid = mido.MidiFile('../MIDI/Fur_Elise_Easy_Piano.mid')
#mid = mido.MidiFile('../MIDI/Beethoven.mid')
def scorri(mid):
    for i, track in enumerate(mid.tracks):
        print('Track {}: {}'.format(i, track.name)) 
        for msg in track:
            #if msg.is_meta:
            print(msg)
        #if msg.type == 'note_on' or  msg.type == 'note_off':
         #   print(msg)
            
def playWithSeconds(mid):
    print("QUI")    
    # Inizializza il tempo dell'ultimo messaggio
    last_time = 0
    overall_time = 0
    # Itera attraverso i messaggi MIDI
    for msg in mid.play():
        # Calcola il tempo trascorso dal messaggio precedente
        delta_time = msg.time - last_time
        last_time = msg.time
        if (delta_time > 0):
            overall_time += delta_time
        # Stampa il messaggio e il tempo trascorso
    print(f'{msg} - Delta time: {delta_time:.3f} seconds')
    print(f'{msg} - Overall time: {overall_time:.3f} seconds')
        


def jsonFromMIDI(mid, filename):
    # Initialize the list of notes
    notes = []

    # Iterate through the MIDI messages
    for msg in mid.play():
        # Add the note to the list if the message is a note
        if msg.type == 'note_on':
            notes.append({
                'note': msg.note,
                'velocity': msg.velocity,
                'time': msg.time
            })

    # Write the list of notes to a JSON file
    with open(filename+'.json', 'w') as f:
        json.dump(notes, f)
#jsonFromMIDI(mid, "prova")
#ticks_per_beat = mid.ticks_per_beat
#print(ticks_per_beat)

#scorri(mid)
#mido.merge_tracks(mid.tracks))
#exit()
#playWithSeconds(mid)



#In this example, the midi_to_note() function takes a MIDI note number as input and returns the corresponding note symbol. The function first calculates the octave number by dividing the MIDI note number by 12 and subtracting 1. It then calculates the note number by taking the MIDI note number modulo 12. Finally, it returns the note symbol by concatenating the note name with the octave number.
#For example, the MIDI note number 69 corresponds to the note A4. The midi_to_note() function returns the string 'A4' for this input.
def midi_to_note(midi_note):
    """Convert a MIDI note number to a note symbol."""
    notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (midi_note // 12) - 1
    note = midi_note % 12
    return notes[note] + str(octave)




def myParse(mid):
    print("PLAYBACK TIME IN SECONDS (i.e., This will be computed by going through every message in every track and adding up delta times.): "+ str(mid.length))

    ticks_per_beat = mid.ticks_per_beat
    print("TICKS PER BEAT: " + str(ticks_per_beat))

    time = 0
    ticks = 0
    #for msg in mid:  -> SE ITERIAMO I MESSAGI IN QUESTO MODO OTTENIAMO IL msg.time (DELTA DAL PRECEDENTE MESSAGIO) IN SECONDI
    #for msg in mid.tracks[0]: -> INVECE, SE ITERIAMO I MESSAGI COSì IL msg.time (DELTA DAL PRECEDENTE MESSAGIO) IN TICKS
    lastBarTime = 0
    lastBarTicks = 0
    
    timeSignatures = []
    tempos = []
    song = []
    notes = []
    bars=[]
    barsCounter = 0
    #(TUPLE FORMAT)
    #(BAR_index, NOTE in MIDI, NOTE in MUSIC notation, starting_ticks, starting_time, end_ticks, end_time, duration)
    # Define a named tuple with two fields: 'name' and 'age'
    #Person = namedtuple('Person', ['name', 'age'])
    Note = namedtuple('Note', ['startBar','endBar','midiNote','note','ticks','durationTicks', 'time', 'durationTime', 'velocity'])
    TimeSignature = namedtuple('TimeSignature', ['numerator','denominator','ticks','time'])
    Tempo = namedtuple('Tempo', ['bpm','ticks','time','msgtime'])
    Bar = namedtuple('Bar', ['index','ticks','durationTicks','time','durationTime'])
    
    tempo=-1
    
    for msg in mid:
        print(msg)
        #print("QUI")
        if msg.time >0:
            time += msg.time
        #print("msg.time: " +str(msg.time))
        #print("time: " +str(time))
        if tempo != -1:
            tick = mido.second2tick(msg.time, ticks_per_beat, tempo)
            
            ticks += tick
            print("ticks: " +str(ticks))
            
            #print("mido.tick2second(ticks): " +str(mido.tick2second(ticks, ticks_per_beat, tempo)))
            
          
        
        
        
        if msg.type == 'set_tempo':
            #print("SET TEMPO: "+ str(msg.tempo))
            tempo = msg.tempo
            tempos.append(Tempo(60000000/tempo,ticks,time,msg.time))
            #print("TEMPO :): "+str(60000000/tempo))
            
            #print("TEMPO :): "+str(mido.tempo2bpm(tempo)))
            #print(msg)
            #print("QUA")
          #  print("tick: " +str(tick))
            #print("ticks: " +str(ticks))
            #print("time: " +str(time))
            #print("mido.tick2second(ticks): " +str(mido.tick2second(ticks, ticks_per_beat, 500000)))
            #print("mido.tick2second(ticks): " +str(mido.tick2second(ticks, ticks_per_beat, 1000000)))
            #print("mido.tick2second(ticks): " +str(mido.tick2second(ticks, ticks_per_beat, 365854)))
            #print("mido.tick2second(ticks): " +str(mido.tick2second(ticks, ticks_per_beat, tempo)))
            #print("mido.tick2second(tick): " +str(mido.second2tick(msg.time, ticks_per_beat, tempo)))
            #print("mido.tick2second(tick): " +str(mido.second2tick(msg.time, ticks_per_beat, 500000)))
            #print("mido.tick2second(tick): " +str(mido.second2tick(msg.time, ticks_per_beat, 1000000)))
            #print("mido.tick2second(tick): " +str(mido.second2tick(msg.time, ticks_per_beat, 365854)))
            
            #bpm = tempo2bpm(message.tempo)
        elif msg.type == 'time_signature':
            numerator = msg.numerator
            denominator = msg.denominator
            print("TIME SIGNATURE: " + str(numerator) + "/" + str(denominator))
            timeSignatures.append(TimeSignature(numerator,denominator,ticks,time))
        
            barTimeInTicks = ticks_per_beat * numerator
            print("BAR TIME IN TICKS: " + str(barTimeInTicks))
              
        elif msg.type == 'note_on':            
           
            
            #print((f' rel:> {msg.time}'))
            #print(f' abs:> {time}')
            #print(round(msg.time,3) )
            #print(time)
            #
            if tick != 0 and ticks % barTimeInTicks == 0: #la condizione su tick!=0 è fondamentale per evitare che note sicrone(quindi con tick=0) facciano rimanere uguale a un caso precedente il valore di barTimeInTicks
            #if tick != 0 and (ticks - lastBarTicks) > barTimeInTicks: 
                print("---BARSCOUNTER--- " +str(barsCounter))
                print("---barTimeInTicks--- " +str(barTimeInTicks))
                
                #FINISCE QUI UNA BATTUTA
                bars.append(Bar(barsCounter,lastBarTicks,ticks-lastBarTicks,lastBarTime,time-lastBarTime))
                lastBarTicks=ticks
                lastBarTime=time
                barsCounter+=1
                # MEGLIO QUESTO APPROCCIO
                print("TICKS======ENDoFBAR!!!=========TICKS: " +str(ticks) +", " + str(ticks % barTimeInTicks))
                
                #bars.append(bar)
                #print(bar)
                #print(bars)   
                #bar = []
                
            #print(msg) 
            
            if msg.velocity != 0:
                #INIZIO NOTA
                #print("ON")
                notes.append((barsCounter,msg.note,midi_to_note(msg.note),ticks,time,msg.velocity))
            else:
                #velocity = 0 come note_off determina il fine nota
                #FINE NOTA
                #print("OFF")    
                note_off = cerca_e_rimuovi_da_lista_di_tuple(notes, msg.note, 1)
                #print(note_off)
                song.append(Note(note_off[0],barsCounter,msg.note,note_off[2],note_off[3],ticks-note_off[3], round(note_off[4],3),round(time-note_off[4],3), note_off[5]))
               
                
            
            #if math.ceil(time * 100) / 100 - lastBarAbsoluteTime >= barTimeInSeconds:
            #if time - lastBarAbsoluteTime >= barTimeInSeconds:
            #   lastBarAbsoluteTime = time
            #   print("======ENDoFBAR!!!=========" + str(lastBarAbsoluteTime))
                
            #print(msg.time)
            #print(midi_to_note(msg.note))
            
            
           # print("TICK---->: " + str(tick))
        #    print("TICKS---->: " + str(ticks))
         #   print("TIME---->: " + str(time))
          #  print("MSG.TIME---->: " + str(msg.time))
            #print("second2tick---->: " + str(mido.second2tick(time, ticks_per_beat, tempo)))
            #print("tick2seconds---->: " + str(mido.tick2second(ticks, ticks_per_beat, tempo)))
            
            
           # print(ticks)
        elif msg.type == 'note_off':
            print("WEIII")       
            note_off = cerca_e_rimuovi_da_lista_di_tuple(notes, msg.note, 1)
            #print(note_off)
            song.append(Note(note_off[0],barsCounter,msg.note,note_off[2],note_off[3],ticks-note_off[3], round(note_off[4],3),round(time-note_off[4],3), note_off[5]))
                 
                
       
            
        #    print("TEMPO (i.e., MICROSECONDS PER BEAT, THE DEFINITION OF BEAT DEPEND ON THE TIME SIGNATURE DENOMINATOR): " + str(tempo))
           # barTimeInSeconds = (tempo * numerator) / 1000000 #(/1000000 perchè trasformiamo microsecondi in secondi)
         #   print("BAR TIME IN SECONDS: " +str(barTimeInSeconds) + "s")
        #elif msg.is_meta:
             #print(msg)  
              
    print(time) 
    print(mid.length)
    print(timeSignatures)
    print(tempos)

    note_dicts = [note._asdict() for note in song]
    tempo_dicts = [tempo._asdict() for tempo in tempos]
    ts_dicts = [ts._asdict() for ts in timeSignatures]
    bars_dicts = [bar._asdict() for bar in bars]
    
    res = {'TEMPOS': tempo_dicts, 'TIME_SIGNATURES': ts_dicts,'BARS': bars_dicts,'NOTES': note_dicts}
    #res.append(song)
    #song.append(tempos)
    # Converti la lista di named tuple in una lista di dizionari
    #note_dicts = [n._asdict() for n in song]
    #note_dicts = [[el._asdict() for el in l] for l in res] #[[float(y) for y in x] for x in my_list_of_lists]
    # Serializza la lista di dizionari in JSON
    #json_output = json.dumps(note_dicts, indent=4)  # Puoi personalizzare l'indentazione
    json_output = json.dumps(res, indent=4)  # Puoi personalizzare l'indentazione
    # Scrivi il JSON su un file
    with open(midFilename+'_output.json', 'w') as f:
        f.write(json_output)

def cerca_e_rimuovi_da_lista_di_tuple(lista_di_tuple, valore_in_tupla, indice_tupla):
    try:
        # Trova l'indice dell'elemento nella lista di tuple
        indice = next(i for i, tupla in enumerate(lista_di_tuple) if tupla[indice_tupla] == valore_in_tupla)
        # Rimuovi l'elemento dalla lista di tuple
        #print(f"L'elemento con valore {valore_in_tupla} è stato trovato e rimosso.")
        return lista_di_tuple.pop(indice)
    except StopIteration:
        #print(f"L'elemento con valore {valore_in_tupla} non è presente nella lista di tuple.")
        return None
    
#mia_lista_di_tuple = [(1, 'a'), (2, 'b'), (3, 'c'), (4, 'd')]
#valore_da_cercare = 3
#cerca_e_rimuovi_da_lista_di_tuple(mia_lista_di_tuple, valore_da_cercare,0)
#print("Lista di tuple aggiornata:", mia_lista_di_tuple)
#exit()
myParse(mid)


