__includes [ "music-utils.nls" "python-music.nls" "food-sources-patterns.nls"]

extensions [shell]

breed [turtles-heads turtle-head] ;turtle-head è la tartaruga classica, tail serve per visualizzare la linea che descrive la sua traiettoria nel tempo
breed [tails tail]
tails-own [age]


patches-own
[
  val       ; each patch has a "fitness" value associated with it
            ; the goal of the particle swarm is to find the patch with the best fitness value
  chemical  ; amount of chemical on this patch for ant-like behaviour
]

turtles-heads-own
[
  vx                  ; velocity in the x direction
  vy                  ; velocity in the y direction

  personal-best-val   ; best value I've run across so far
  personal-best-x     ; x coordinate of that best value
  personal-best-y     ; x coordinate of that best value

  distance-to-others  ; lista di distanze tra la tartaruga e le altre tartarughe, utile per il calcolo della cohesion-GLOBAL
  distance-to-others-in-radius  ; lista di distanze tra la tartaruga e le altre tartarughe, utile per il calcolo della cohesion-LOCAL
  mean-of-distances-in-radius
]

globals
[

;  R ;radius for the neighborhood definition
  sources-start-ycoord
  global-best-x    ; x coordinate of best value found by the swarm
  global-best-y    ; y coordinate of best value found by the swarm
  global-best-val  ; highest value found by the swarm
;  true-best-patch  ; patch with the best value

  perturbation-noise
  perturbation-duration-counter

  ; FILES
  barsDurations                       ;list containing the durations of each bar
  indexBarsDurations                  ;index for iterating over the "barsDurations" list

  entropies

  volumes

  sync                                ;serve per sincronizzare la lettura dei valori che controllano la simulazione con la durata della battuta musicale
  toStop

  grid_ncols                          ; definisce la grandezza del mondo

  patches-functions                   ; lista di funzioni che generano i pattern di food source
  patterns-list                       ; lista di pattern di food sources
  current-pattern                     ; pattern da visualizzare in questo momento
  next-pattern                        ; prossimo pattern da visualizzare nella griglia di patch
  pattern-tick-counter                ; usato per tenere traccia del numero di tick passati da quando si è cambiato il ppattern di food sources
  food-sources-patterns-noise?        ; variabile booleana per decidere se applicare o meno il rumore sulla griglia
  noise-on-world                      ; rumore applicato sulla griglia
  food-source-diffusion-repetitions   ; numero di ripetizioni
  food-source-diffusion-val           ; valore di diffusione
  max-patch-val                       ; valore di patch massimo, punto di valore massimo delle food source
  max-patch-noise-val                 ; valore di patch massimo per quanto riguarda il rumore di fondo del mondo

  cohesion-global                            ; boids-like cohesion-global
  cohesion-local                            ; boids-like cohesion-global
]

; Modifica il valore delle patch al click del mouse
to patch-mouse-change-val
  let increment 0.6
  let factor-of-diffusion 4
  let radius-of-action 5

  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;ask patch mouse-xcor mouse-ycor [ set val val + increment]
      let center-patch patch mouse-xcor mouse-ycor
      ask center-patch
      [
        set val val + increment
        ask other patches in-radius radius-of-action with [self != center-patch]
        [ set val val + (increment / factor-of-diffusion) ]
      ]
      ;ask patch mouse-xcor mouse-ycor
      ;[ ask other patches in-radius 7
       ; [
        ;  set val val + increment
        ;]
      ;]
    ]
end

to setup
  clear-all

  set-default-shape tails "line"


  initialize-world
  set food-sources-patterns-noise? TRUE ;QUESTA VARIABILE DECIDE LA PRESENZA (true) O MENO (false) DEL RUMORE SULLA GRIGLIA

  set food-source-diffusion-repetitions 60
  set food-source-diffusion-val 0.5
  set max-patch-val 0.97
  set max-patch-noise-val 0.03   ; questo deve essere assegnato prima di "initialize-rnd-noise-on-the-world"
  initialize-rnd-noise-on-the-world



  ; INIZIALIZZA PATTERN DI FOOD SOURCES - START
  set patches-functions ["circles-2" "circles-3" "circles-4" "up-down-2-1" "up-down-1-2"]
  set patterns-list initialize_patterns patches-functions grid_ncols

  ;let pttn_1 item 0 patterns-list
  ;let pttn_2 item 1 patterns-list
  ;let fade_1_2 sum-of-matrices pttn_1 pttn_2 grid_ncols 0.9
  ;set-pattern-to-grid fade_1_2 grid_ncols
  ;visualize-patches

  set current-pattern one-of patterns-list ;RND (current) FOOD SOURCE PATTERN
  set next-pattern one-of patterns-list    ;RND (next) FOOD SOURCE PATTERN
  set-pattern-to-grid current-pattern grid_ncols
  visualize-patches
  ; INIZIALIZZA PATTERN DI FOOD SOURCES - END


  set sync FALSE
  set toStop FALSE
  ;;; IMPORT BAR DURATIONS FILE - START;;;
  ;set barsDurations [1 2 1 3 6]
  let barDurationsFilename word MIDI_file "_output.json_barDurations.txt"
  set barsDurations read-list-from-file barDurationsFilename
  print barsDurations
  set indexBarsDurations 0
  ;;; IMPORT BAR DURATIONS FILE - END;;;

  ;;; ------------------------------ ;;;

  ;;; IMPORT ENTROPIES FILE - START;;;
  ;set barsDurations [1 2 1 3 6]
  let entropiesFilename word MIDI_file "_output.json_entropies.txt"
  set entropies read-list-from-file entropiesFilename
  print entropies
  ;;; IMPORT ENTROPIES FILE - END;;;

  ;;; ------------------------------ ;;;

    ;;; IMPORT VOLUMES FILE - START;;;
  ;set barsDurations [1 2 1 3 6]
  let volumesFilename word MIDI_file "_output.json_meanVolumes.txt"
  set volumes read-list-from-file volumesFilename
  print volumes
  ;;; IMPORT ENTROPIES FILE - END;;;

  ;;; ------------------------------ ;;;



  ; MUSIC in python
  music-python-setup
  set perturbation-duration-counter perturbation-duration
  set perturbation-noise FALSE
  ;play-python-music



  ;;; RANDOM PATTERN IN PATCHES start ;;;
  ;set lista-funzioni ["circles-2" "circles-3" "circles-4"];"letter-c"]
  ;call-random-function lista-funzioni

  ;visualize-patches
  ;;; RANDOM PATTERN IN PATCHES end ;;;


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; START COPIED CODE ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; create particles and place them randomly in the world
  create-turtles-heads population-size
  [
    setxy random-xcor random-ycor
    ; give the particles normally distributed random initial velocities for both x and y directions
    set vx random-normal 0 1
    set vy random-normal 0 1
    ; the starting spot is the particle's current best location.
    set personal-best-val val
    set personal-best-x xcor
    set personal-best-y ycor

    ; choose a random basic NetLogo color, but not gray
   ; set color green ;;one-of (remove-item 0 base-colors)
    set color [0 204 0 255];verde con l'ultimo parametro che specifica il canale alpha 0 il minimo e 255 il massimo
    ; make the particles a little more visible
    set size 1.5
    set shape "bug"
    set distance-to-others []
    set distance-to-others-in-radius []
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; END COPIED CODE ;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if testing-turtles?
   [
      ask turtles-heads [
        ;;set personal-best-val random 10 for test only
        let S (word "who: " who " val: " personal-best-val)
        ;;print S
        set label S

        ;; neighborhood best
        ;print who
        ;let Ri 10
        ;show turtles-heads in-radius Ri
        ;ask turtles-heads in-radius Ri [show who]
        ;show max-one-of turtles-heads in-radius Ri [personal-best-val]
        ;ask max-one-of turtles-heads in-radius Ri [personal-best-val] [show personal-best-val]
      ]
  ]


  reset-ticks
end


to turtle-pso
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; START COPIED CODE ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ask turtles-heads [

    ; update the "personal best" location for each particle,
    ; if they've found a new value better than their previous "personal best"
    if val > personal-best-val
    [
      set personal-best-val val
      set personal-best-x xcor
      set personal-best-y ycor
    ]

    ; print "val"
     ;print val
     ;print "personal-best-val"
     ;print personal-best-val

     ;;memory
     ;;set personal-best-val personal-best-val * memory

     ;;print "after memory"
     ;;print personal-best-val
  ]


  ; update the "global best" location for the swarm, if necessary.
   ask max-one-of turtles-heads [personal-best-val]
  [
    if global-best-val < personal-best-val
    [
      set global-best-val personal-best-val
      set global-best-x personal-best-x
      set global-best-y personal-best-y
    ]

    ;print "global-best-val"
    ; print global-best-val

      ;;memory
    ;;set global-best-val global-best-val * memory
    ;;print personal-best-val

     ;;print "after memory GLOBAL"
    ;;print global-best-val
  ]
  ;;if global-best-val = [val] of true-best-patch
    ;;[ stop ]


  ask turtles-heads
  [
    ;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; NEIGHBORHOOOD ;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;

    ;show turtles-heads in-radius R
    ;ask turtles-heads in-radius R [show who]
    ;show max-one-of turtles-heads in-radius R [personal-best-val]
    ;let be max-one-of turtles-heads in-radius R [personal-best-val]
    ;show [personal-best-val] of be
    ;;

    let neigh-best-x [personal-best-x] of max-one-of turtles-heads in-radius R [personal-best-val]
    let neigh-best-y [personal-best-y] of max-one-of turtles-heads in-radius R [personal-best-val]

    if testing-turtles?
    [
      print "who"
      print who
      print personal-best-x
      print personal-best-y
      print "best"
      print neigh-best-x
      print neigh-best-y
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; NEIGHBORHOOOD ;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;


    set vx particle-inertia * vx
    set vy particle-inertia * vy

    ; Technical note:
    ;   In the canonical PSO, the "(1 - particle-inertia)" term isn't present in the
    ;   mathematical expressions below.  It was added because it allows the
    ;   "particle-inertia" slider to vary particles motion on the the full spectrum
    ;   from moving in a straight line (1.0) to always moving towards the "best" spots
    ;   and ignoring its previous velocity (0.0).

    ; change my velocity by being attracted to the "personal best" value I've found so far
    facexy personal-best-x personal-best-y
    let dist distancexy personal-best-x personal-best-y
    set vx vx + (1 - particle-inertia) * attraction-to-personal-best * (random-float 1.0) * dist * dx
    set vy vy + (1 - particle-inertia) * attraction-to-personal-best * (random-float 1.0) * dist * dy

    ; change my velocity by being attracted to the "global best" value anyone has found so far
    facexy global-best-x global-best-y
    set dist distancexy global-best-x global-best-y
    set vx vx + (1 - particle-inertia) * attraction-to-global-best * (random-float 1.0) * dist * dx
    set vy vy + (1 - particle-inertia) * attraction-to-global-best * (random-float 1.0) * dist * dy

    ; change my velocity by being attracted to the "neighborhood best" value anyone has found so far
    facexy neigh-best-x neigh-best-y
    set dist distancexy neigh-best-x neigh-best-y
    set vx vx + (1 - particle-inertia) * attraction-to-neigh-best * (random-float 1.0) * dist * dx
    set vy vy + (1 - particle-inertia) * attraction-to-neigh-best * (random-float 1.0) * dist * dy

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;; ANT BEHAVIOUR START ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;let sniff-pheromone-at-distance 5
    let ptch-ahead patch-at-angle-dist  0  sniff-pheromone-at-distance ;; patch in front at distance 1
    let ptch-right patch-at-angle-dist  45 sniff-pheromone-at-distance ;; patch to the right
    let ptch-left  patch-at-angle-dist -45 sniff-pheromone-at-distance ;; patch to the left

;    print [chemical] of ptch-ahead

    let scent-ahead patch-chemical ptch-ahead ;; chemical of patch in front at distance 1
    let scent-right patch-chemical ptch-right ;; chemical of patch to the right
    let scent-left  patch-chemical ptch-left  ;; chemical of patch to the left


    if (scent-right > scent-ahead) or (scent-left > scent-ahead)
    [ ifelse scent-right > scent-left
      [
        ;show [list pxcor pycor] of ptch-right
         let ant-x [pxcor] of ptch-right
         let ant-y [pycor] of ptch-right
         facexy ant-x ant-y
         ;set dist distancexy ant-x ant-y
         set dist sniff-pheromone-at-distance
         set vx vx + (1 - particle-inertia) * attraction-to-pheromone * (random-float 1.0) * dist * dx
         set vy vy + (1 - particle-inertia) * attraction-to-pheromone * (random-float 1.0) * dist * dy
      ]
      [
         let ant-x [pxcor] of ptch-left
         let ant-y [pycor] of ptch-left
         facexy ant-x ant-y
         ;set dist distancexy ant-x ant-y
         set dist sniff-pheromone-at-distance
         set vx vx + (1 - particle-inertia) * attraction-to-pheromone * (random-float 1.0) * dist * dx
         set vy vy + (1 - particle-inertia) * attraction-to-pheromone * (random-float 1.0) * dist * dy
      ]
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;; ANT BEHAVIOUR END ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;


    ; speed limits are particularly necessary because we are dealing with a toroidal (wrapping) world,
    ; which means that particles can start warping around the world at ridiculous speeds
    if (vx > particle-speed-limit) [ set vx particle-speed-limit ]
    if (vx < 0 - particle-speed-limit) [ set vx 0 - particle-speed-limit ]
    if (vy > particle-speed-limit) [ set vy particle-speed-limit ]
    if (vy < 0 - particle-speed-limit) [ set vy 0 - particle-speed-limit ]

    ;; random component
    ifelse perturbation-noise
    [
      set vx vx + random-normal 0 perturbation-entity
      set vy vy + random-normal 0 perturbation-entity
    ]
    [
      set vx vx + random-normal 0 normal-noise-std
      set vy vy + random-normal 0 normal-noise-std
    ]

    ;set vx vx + random-normal 0 normal-noise-std
    ;set vy vy + random-normal 0 normal-noise-std


    ; face in the direction of my velocity
    facexy (xcor + vx)  (ycor + vy)
    ; and move forward by the magnitude of my velocity
    forward sqrt (vx * vx + vy * vy )


    ;;memory
    set personal-best-val personal-best-val * memory
    set global-best-val global-best-val * memory


    if consumes-the-dance-floor?
    [
      consume-patch-value
    ]
    ;print "after memory"
    ;print personal-best-val
    ;print "after memory GLOBAL"
    ;print global-best-val
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; END COPIED CODE ;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end


;;consuma valore delle patches
to consume-patch-value
  let current-patch patch-here
  if current-patch != nobody [
    let patch-value [val] of current-patch
    ; decrementa il valore della patch
    ask current-patch [ set val val - dance-floor-consumption]
  ]
end




to music-python
  play-python-music
  every every-python-ticks-duration [
    set pattern-tick-counter 0 ;RESET DEL CONTATORE CHE TIENE TRACCIA DEL NUMERO DI TICK PASSATI DAL CAMBIO DI PATTERN
    set current-pattern next-pattern
    set next-pattern one-of patterns-list

     ;call-random-function lista-funzioni

     ;visualize-patches

    ;; random component
    ;ask turtles-heads
    ;[
    ;set vx vx + random-normal 0 5
    ;set vy vy + random-normal 0 5
    ;]
    if perturbation-allowed
    [
      set perturbation-noise TRUE
    ]

    set sync FALSE

    ifelse indexBarsDurations < length barsDurations
    [
      set indexBarsDurations indexBarsDurations + 1
      print indexBarsDurations
      print barsDurations
    ]
    [
      print "TOSTOP"
      set toStop TRUE
    ]

  ]
end



to go
  ;music-utils
  ;set attraction-to-neigh-best 0

  if sync = FALSE
  [
    set sync TRUE

    ifelse toStop = FALSE
    [
      if indexBarsDurations < length barsDurations
      [
        ;;;; BAR DURATION - START ;;;
        let durationString item indexBarsDurations barsDurations
        let durationNumber read-from-string (word durationString "")
        set every-python-ticks-duration durationNumber
        ;set every-python-ticks-duration item indexBarsDurations barsDurations
        ;print every-python-ticks-duration
        ;;;; BAR DURATION - END ;;;;;

        ;;; ------------------------------ ;;;

        ;;;; USE OF ENTROPY - START ;;;
        let entropyString item indexBarsDurations entropies
        let entropyNumber read-from-string (word entropyString "")
        ;let rescaledEntropy rescale-value entropyNumber 0 1 0 0.4 ; valore riscalato di entropia tra 0 e 0.5
        ;set normal-noise-std rescaledEntropy
        let invertRescaledEntropy inverti-valore entropyNumber 0 1 1 2
        set attraction-to-neigh-best invertRescaledEntropy
        print invertRescaledEntropy
        ;;;; USE OF ENTROPY - END ;;;

        ;;; ------------------------------ ;;;

        ;;;; USE OF VOLUMES - START ;;;
        let volumeString item indexBarsDurations volumes
        let volumeNumber read-from-string (word volumeString "")
        let invertRescaledVolume rescale-value volumeNumber 0 1 0 0.2
        set normal-noise-std invertRescaledVolume
        print invertRescaledVolume
      ]
    ]
    [
      end-python-music
      stop
    ]


  ]



  food-sources-patterns-fading ;fading tra modno corrente e successivo

  music-python
  turtle-pso
  turtle-ant
  patch-mouse-change-val

  set current-pattern retrieve-patches-matrix grid_ncols; questo ci permette di leggere lo stato del mondo tick per tick, e permette il consumo delle patch



  ;visualize-patches

  if perturbation-noise ;;se TRUE
  [
    ifelse perturbation-duration-counter > 0
    [
      set perturbation-duration-counter perturbation-duration-counter - 1
    ]
    [
      set perturbation-noise FALSE
      set perturbation-duration-counter perturbation-duration
    ]
  ]

  ifelse particles-tails?
  [
    ask tails [
      set color [0 204 0 90]
      set age age + 1
      if age = 9 [ die ]
    ]
    ask turtles-heads [
      hatch-tails 1
    ]
  ]
  [
    ask tails [die]
  ]

  ;;;; cohesion-local - START;;;;

  ask turtles-heads [
    ask other turtles-heads in-radius 10[
      ;print myself
      ;print who
      ; calcolo delle distaze tra tartarughe, per ogni tartaruga
      let dist distance myself
      set distance-to-others-in-radius lput dist distance-to-others-in-radius
    ]
   ; let nearby-turtles other turtles-heads in-radius radius
   ; show (word "Tartaruga " who " ha trovato: " count nearby-turtles " tartarughe vicine")
    ifelse length distance-to-others-in-radius > 0
    [
      set mean-of-distances-in-radius mean distance-to-others-in-radius
    ]
    [
      set mean-of-distances-in-radius 0
    ]
  ]
  set cohesion-local mean [mean-of-distances-in-radius] of turtles-heads ; calcolo della cohesion-global globale
  ;;;; cohesion-local - END;;;;


  ;;;; cohesion-global - START;;;;
  ask turtles-heads [
    ask other turtles-heads
    [
       ; calcolo delle distaze tra tartarughe, per ogni tartaruga
       let dist distance myself
       set distance-to-others lput dist distance-to-others
    ]
  ]
  set cohesion-global mean [(sum distance-to-others) / length distance-to-others] of turtles-heads ; calcolo della cohesion-global globale

  ;reset lists
  ask turtles-heads [
    set distance-to-others []                   ; we reset the computation of the cohesion-GLOBAL value
    set distance-to-others-in-radius []         ; we reset the computation of the cohesion-LOCAL value
  ]
  ;;;; cohesion-global - END;;;;
  tick

end

; RICHIAMATO DAL METODO "GO" PRODUCE IL FADING TRA I PATTERN CURRENT E NEXT
to food-sources-patterns-fading
  ;  FADING TRA FOOD SOURCES
  let alpha-fade pattern-tick-counter / food-sources-fading-ticks
  if alpha-fade > 1
  [
    set alpha-fade 1
  ]
  let fade_1_2 sum-of-matrices current-pattern next-pattern grid_ncols  (1 - alpha-fade) ; avendo limitato superiormente alpha-fade a 1 al massimo si vedrà già il secondo pattern
  set-pattern-to-grid fade_1_2 grid_ncols
  visualize-patches
  set pattern-tick-counter pattern-tick-counter + 1 ;incrementa il counter per la transizione tra food sources pattern

end





;;;;;;;;;;;;;;;;;;;;;;
; ANT-LIKE BEHAVIOUR ;
;;;;;;;;;;;;;;;;;;;;;;

to turtle-ant
  ask turtles-heads
  [
    set chemical chemical + 60 ;; drop some chemical
  ]
  diffuse chemical (diffusion-rate / 100)
  ask patches
  [ set chemical chemical * (100 - evaporation-rate) / 100 ] ;; slowly evaporate chemical
    ;;recolor-patch ]
  if visualize-pheromone?
  [
   ; se non è attivo non coloriamo le patch con il relativo valore di feromone
   recolor-patch
  ]
end


to recolor-patch  ;; patch procedure
   ;; scale color to show chemical concentration
  ask patches
  [
    set pcolor scale-color green chemical 0.1 5
   ]
end

to-report patch-at-angle-dist [angle dist]
  ;let p patch-right-and-ahead angle 1
  let p patch-right-and-ahead angle dist
  ;if p = nobody [ report 0 ]
  ;report [chemical] of p
  report p
end

to-report patch-chemical [ptch]
  if ptch = nobody [
    report 0
  ]
  report [chemical] of ptch ;; chemical of patch
end


;;;;;;;;;;;;;;;;;;;;;;
; ANT-LIKE BEHAVIOUR ;
;;;;;;;;;;;;;;;;;;;;;;




to call-random-function [function-list]
  let random-function one-of function-list
  run random-function
end



;leggi da file
to-report read-list-from-file [filename]
  let data []
  file-open filename
  while [not file-at-end?] [
    let line file-read-line
    set data lput line data
  ]
  file-close
  report data
end

; Esempio di utilizzo
;let my-data read-list-from-file "lista_numeri.txt"
;show my-data


;; Normalizza valore nel range di valori dato
to-report rescale-value [value old-min old-max new-min new-max]
  report new-min + ((value - old-min) * (new-max - new-min) / (old-max - old-min))
end

;; Inverte il valore in un nuovo specificato range
to-report inverti-valore [value old-min old-max new-min new-max]
  let valore_invertito new-min + ((new-max - new-min) * (1 - ((value - old-min) / (old-max - old-min))))
  report valore_invertito
end
@#$#@#$#@
GRAPHICS-WINDOW
340
34
848
543
-1
-1
7.8125
1
10
1
1
1
0
0
0
1
0
63
0
63
1
1
1
ticks
30.0

BUTTON
66
20
132
53
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
145
20
208
53
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
61
98
177
158
population-size
100.0
1
0
Number

SLIDER
62
172
234
205
particle-inertia
particle-inertia
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
62
218
289
251
attraction-to-personal-best
attraction-to-personal-best
0
2
1.9
0.1
1
NIL
HORIZONTAL

SLIDER
64
263
275
296
attraction-to-global-best
attraction-to-global-best
0
2
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
66
314
243
347
particle-speed-limit
particle-speed-limit
0
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
59
389
267
422
attraction-to-neigh-best
attraction-to-neigh-best
0
2
1.0302761001317529
0.1
1
NIL
HORIZONTAL

INPUTBOX
58
437
131
497
R
4.0
1
0
Number

SWITCH
883
618
1044
651
testing-patches?
testing-patches?
1
1
-1000

SLIDER
62
548
234
581
memory
memory
0
1
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
61
590
233
623
normal-noise-std
normal-noise-std
0
3
0.2
0.1
1
NIL
HORIZONTAL

SWITCH
883
577
1035
610
testing-turtles?
testing-turtles?
1
1
-1000

SLIDER
878
62
1050
95
evaporation-rate
evaporation-rate
0
100
60.0
10
1
NIL
HORIZONTAL

SLIDER
881
113
1053
146
diffusion-rate
diffusion-rate
0
100
80.0
10
1
NIL
HORIZONTAL

SLIDER
880
164
1091
197
attraction-to-pheromone
attraction-to-pheromone
0
2
1.4
0.1
1
NIL
HORIZONTAL

TEXTBOX
903
38
1053
56
Ant-like behaviour
12
0.0
1

TEXTBOX
928
544
1078
562
Testing
12
0.0
1

TEXTBOX
65
364
215
382
Local best
12
0.0
1

TEXTBOX
63
518
213
536
Memory & Noise
12
0.0
1

TEXTBOX
64
75
214
93
Standard PSO
12
0.0
1

SLIDER
880
220
1116
253
sniff-pheromone-at-distance
sniff-pheromone-at-distance
1
10
5.0
1
1
NIL
HORIZONTAL

SWITCH
881
274
1075
307
visualize-pheromone?
visualize-pheromone?
1
1
-1000

SWITCH
881
394
1114
427
consumes-the-dance-floor?
consumes-the-dance-floor?
1
1
-1000

SLIDER
881
351
1097
384
dance-floor-consumption
dance-floor-consumption
0
1
0.17
0.01
1
NIL
HORIZONTAL

TEXTBOX
913
325
1063
343
Dance floor consumption
12
0.0
1

BUTTON
620
599
769
632
NIL
end-python-music
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
352
602
540
635
perturbation-allowed
perturbation-allowed
0
1
-1000

SLIDER
353
652
526
685
perturbation-entity
perturbation-entity
0
2
1.2
0.1
1
NIL
HORIZONTAL

INPUTBOX
354
693
503
753
perturbation-duration
3.0
1
0
Number

SWITCH
881
441
1071
474
visualize-dance-floor
visualize-dance-floor
0
1
-1000

BUTTON
883
489
1098
522
NIL
ask patches [set pcolor black]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
354
571
609
603
Perturbation upon dance-floor change
13
0.0
1

BUTTON
886
666
1033
699
test import files
show read-list-from-file \"MIDI/bach-Canon-a-2.midoutput.json-bar-durations.txt\"\nshow read-list-from-file \"MIDI/bach-Canon-a-2.midoutput.json-entropies.txt\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
620
645
849
705
MIDI_file
MIDI/Fur_Elise_Easy_Piano.mid
1
0
String

TEXTBOX
707
572
857
590
Music
13
0.0
1

BUTTON
887
700
1251
733
Test-dancefloor-basic-patterns
ask patches [ set val 0]\ncall-random-function patches-functions\nnormalize-patches\nvisualize-patches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
342
778
872
811
NIL
let rnd one-of patterns-list\nset-pattern-to-grid rnd grid_ncols\nvisualize-patches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
92
696
312
729
food-sources-fading-ticks
food-sources-fading-ticks
1
200
86.0
1
1
NIL
HORIZONTAL

SWITCH
1185
85
1333
118
particles-tails?
particles-tails?
1
1
-1000

PLOT
1182
147
1607
332
Cohesion
time
Cohesion
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"global" 1.0 0 -16777216 true "" "plot cohesion-global"
"local" 1.0 0 -5298144 true "" "plot cohesion-local"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
