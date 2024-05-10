# Requirements

- **NetLogo** >= 6.4.x
- **Python** >= 3.10.x
- **Python libraries required**:
  - mido
  - pygame
  - math
  - json

# How to run
## Musical feature extraction from MIDI file:
- Parse the selected MIDI file as follows:
  ```python
  python music-preprocessing.py "MIDIFILENAME.mid"
  ```
- Feature extraction from the previously parsed MIDI:
  ```python
  python fromJSON2Features.py "PRODUCED_JSON.json"
  ```

## Netlogo side:
- Start the NetLogo simulation by opening the "code/NetLogo/SI-dance.nlogo" model;
- Choose the musical track by entering the relative path of the MIDI file in the input component called "MIDI_file" in the GUI; for example, "MIDI/Fur_Elise_Easy_Piano.mid";
- Click the 'Setup' button and then the 'Go' button to actually start the simulation.

# GUI Screenshot

<img width="1309" alt="Screenshot 2024-05-10 at 15 52 31" src="https://github.com/mbraccini/Swarm-intelligence-dance-choreography/assets/4438471/23ab876a-d6d0-4de6-8a38-120f864e32c0">
