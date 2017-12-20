turtles-own
[
  before-sign ;; beginning x coordinate of the car in the right lane before the merge sign
  decide ;; for the "uniform" module
  speed         ;; the current speed of the car
  lane          ;; the current lane of the car
  target-lane   ;; the desired lane of the car
]

; each patch corresponds to 15 feet long

to setup
  clear-all
  draw-road
  reset-ticks
  set-default-shape turtles "car"
  crt number [ setup-cars ] ;; creates cars based on number slider from user input
  if sign = "close" [
    ask patch (max-pxcor - 33.33) -5 [ set pcolor white ] ;; sign about 500 feet ahead of the end
  ]
  if sign = "half-mile" [
    ask patch (max-pxcor - 176) -5 [ set pcolor white ] ;; sign about half a mile ahead of the end
  ]
  if sign = "mile" [
    ask patch (max-pxcor - 352) -5 [ set pcolor white ] ;; sign about a mile ahead of the end
  ]
end

to draw-road
  ask patches [
    set pcolor green
    if ((pycor > -4) and (pycor < 0)) [ set pcolor gray ] ;; road
    if ((pycor = 0) or (pycor = -4)) [ set pcolor black ] ;; side of road
    if ((pycor < -2) and (pycor > -5) and (pxcor > max-pxcor * 0.9)) [ set pcolor orange] ;; blockage/end of lane starts at 0.9 of the distance of the user-set world
  ]
end

to setup-cars
  set color black
  set lane (random 3) ;; pick lane randomly
  set target-lane lane
  if (lane = 0) [ ;; if in bottom/right lane, create cars in front of sign
   if sign = "close" [
      set before-sign random-xcor
      while [ before-sign > max-pxcor - 33.33 ] [
        set before-sign random-xcor
      ]
      setxy before-sign -3
    ]
   if sign = "half-mile" [
     set before-sign random-xcor
     while [ before-sign > max-pxcor - 176 ] [
       set before-sign random-xcor
     ]
     setxy before-sign -3
   ]
   if sign = "mile" [
     set before-sign random-xcor
     while [ before-sign > max-pxcor - 352 ] [
       set before-sign random-xcor
     ]
     setxy before-sign -3
   ]
  ]
  if (lane = 1) [ ;; if in middle lane, distribute cars randomly
    setxy random-xcor -2
  ]
  if (lane = 2) [ ;; if in upper/leftmost lane, distribute cars randomly
    setxy random-xcor -1
  ]
  set heading 90
  set speed 0.1 + random 9.9 ;; set random speed, max is 10 patches/tick which is 102.27 mph
  if case = "uniform" and sign = "close" [ ;; if uniform distribution of cars moving module has been chosen, patch will be assigned at which the car begins to try to merge
    set decide max-pxcor - 33.33 + random (max-pxcor * .75 - (max-pxcor - 33.33)) ;; make 'decide' patch a random patch in the range between seeing the sign and the end
    ]
  if case = "uniform" and sign = "half-mile" [
    set decide max-pxcor - 176 + random (max-pxcor * .75 - (max-pxcor - 176)) ;; range between seeing the sign and the end
    ]
  if case = "uniform" and sign = "close" [
    set decide max-pxcor - 352 + random (max-pxcor * .75 - (max-pxcor - 352)) ;; range between seeing the sign and the end
    ]
  loop [
    ifelse any? other turtles-here [ fd -1 ] [ stop ] ;; make sure no two cars are on the same patch
  ]
end

to drive
  ifelse any? turtles [ ;; only 'goes' if there are turtles/cars present/on the road
   ask turtles [
     if case = "immediate" and [ycor] of self != -2 [ ;; if immediate module then change lanes when it sees the sign
       if sign = "close" [
         if [xcor] of self > max-pxcor - 33.33 [change-lanes] ]
       if sign = "half-mile" [
         if [xcor] of self > max-pxcor - 176 [change-lanes] ]
       if sign = "mile" [
         if [xcor] of self > max-pxcor - 352 [change-lanes] ]
     ]
     if case = "wait" and [xcor] of self > max-pxcor * 0.75 - 3 and [ycor] of self != -2 [change-lanes] ;; if wait module then change lanes near the end of the road
     if case = "uniform" and [ycor] of self = -3 [
       if [xcor] of self > decide [ change-lanes ] ; if uniform module, change lanes when current position has just passed the patch which has been randomly assigned to start merging at
     ]
     ]
   ;; look one ahead and see if someone is ahead, if so, match speed and decelerate to allow for space between cars otherwise accelerate
   ;; if not, check if allowed to see 2 ahead otherwise accelerate
   ask turtles [
     ifelse (any? turtles-at 1 0) [ ;; each car checks to see if there is a car in front of it - if so, sets own speed to front car's speed and decelerate
       set speed ([speed] of (one-of (turtles-at 1 0)))
       decelerate
     ]
     [
       ;; if not car immediately ahead but a little further ahead, match speed of that car and decelerate to allow for space beteen cars
       ifelse (look-ahead = 2) [
         ifelse (any? turtles-at 2 0) [
           set speed ([speed] of (one-of turtles-at 2 0))
           decelerate
         ]
         [
           accelerate ;; if no cars 2 in front then accelerate
         ]
       ]
       [
         accelerate ;; if no cars 1 in front then accelerate
       ]
     ]
     if (speed > speed-limit * 0.0978) [ set speed speed-limit * 0.0978 ] ;; abides by speed limit - 0.0978 is conversion factor from user inputted mph to patches/tick
   ]
   ; Now that all speeds are adjusted, give turtles a chance to change lanes
   ask turtles [
     ;; control for making sure no one crashes
     ifelse (any? turtles-at 1 0) and (xcor != min-pxcor - .5) [ ;; accounts for back of car
       set speed [speed] of (one-of turtles-at 1 0)
     ]
     [
       ifelse ((any? turtles-at 2 0) and (speed > 1.0)) [
         set speed ([speed] of (one-of turtles-at 2 0))
       ]
       [
           ifelse ([ycor] of self = -3 and [xcor] of self + speed > max-pxcor * 0.9) ;; if the x coordinate is going to be past the block then start stopping
           [ begin-stop ]
           [fd speed] ;; otherise continue as normal
       ]
     ]
   ]
   ;; delete turtles that have cleared off the middle or top/leftmost lane that everyone has merged into
   ask turtles [
     if [xcor] of self > max-pxcor - 1 and [ycor] of self = -1 [die]
     if [xcor] of self > max-pxcor - 1 and [ycor] of self = -2 [die]
   ]
   tick
   ]
  [ stop ]
end

;; increase speed of cars
to accelerate
  set speed (speed + (speed-up * 5280 / (15 * 3600))) ; converts mph user input to patch/tick
end

;; reduce speed of cars
to decelerate
  set speed (speed - (slow-down * 5280 / (15 * 3600))) ; converts mph user input to patch/tick
  if (speed < 0.01) [ set speed 0.01 ]
end

;; start stopping completely
to begin-stop
  while [ speed > 0 ] [
    set speed (speed - (slow-down * 5280 / ( 15 * 3600)))
  ]
end

to change-lanes
  ;; at the beginning all target lanes are the same as current lanes
  if any? turtles [
   ifelse (target-lane = lane) [
     if (target-lane = 0) [  ;; if bottom lane then wants to go to middle lane
       set target-lane 1
     ] ;; otherwise do nothing
   ]
   ;; if where the car wants to go (target lane) is not the same as where it is then change lanes

   ;; if the target lane is 1 and it is not in lane 1 and there is not a turtle above it and there is a turtle in front of it then decelerate
   [
     ifelse (target-lane = 1) [
       ifelse (pycor = -2) [ ;; if target lane is 1 but is already in lane 1 according to pycor then set lane as 1, causing to go through above loop instead
         set lane 1
       ]
       [
         ifelse (not any? turtles-at 0 1) [ ;; if target lane is 1 and is not in lane 1 according to pycor then check if there is a car next to it in the lane it wants to move into
           set ycor (ycor + 1) ;; if no cars in desired space then move up
         ]
         [
           ifelse (not any? turtles-at 1 0) [ ;; if cars in desired space in desired lane then move forward according to the folloing
             ifelse xcor + speed < (max-pxcor * 0.95) [ ;; if will not move off the end of the lane in the next step then move forward
             fd speed]
             [decelerate] ;; if will move off the end of the lane in the next step then decelerate instead of maintaining current speed
           ]
           [
             decelerate ;if there are cars right in front of it then decelerate
           ]
         ]
       ]
     ]
     [ ]
   ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
291
10
707
187
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-25
25
-10
10
1
1
1
ticks
30.0

BUTTON
19
21
94
54
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
21
106
96
139
go
drive
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
62
102
95
go once
drive
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
112
14
274
47
number
number
0
134
20.0
1
1
NIL
HORIZONTAL

SLIDER
112
162
274
195
slow-down
slow-down
0
15
15.0
1
1
NIL
HORIZONTAL

SLIDER
112
114
274
147
speed-up
speed-up
0
15
15.0
1
1
NIL
HORIZONTAL

SLIDER
110
62
272
95
look-ahead
look-ahead
1
2
1.0
1
1
NIL
HORIZONTAL

PLOT
9
302
209
452
number of cars vs. ticks
ticks
number of cars
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
109
208
281
241
speed-limit
speed-limit
0
100
35.0
0.1
1
NIL
HORIZONTAL

PLOT
263
297
463
447
speed vs time
time
speed
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -16777216 true "" "if any? turtles [plot mean [speed] of turtles]"
"max" 1.0 0 -7500403 true "" "if any? turtles [plot max [speed] of turtles]"
"min" 1.0 0 -2674135 true "" "if any? turtles [plot min [speed] of turtles]"

CHOOSER
296
228
434
273
sign
sign
"close" "half-mile" "mile"
0

CHOOSER
449
227
587
272
case
case
"immediate" "wait" "uniform"
1

@#$#@#$#@
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
setup
repeat 50 [ drive ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vary agent response" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <exitCondition>ticks = 10000</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="case">
      <value value="&quot;immediate&quot;"/>
      <value value="&quot;wait&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vary place" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>drive</go>
    <exitCondition>ticks = 10000</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sign">
      <value value="&quot;half-mile&quot;"/>
      <value value="&quot;mile&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity" repetitions="25" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>drive</go>
    <exitCondition>any? turtles = false</exitCondition>
    <metric>ticks</metric>
    <enumeratedValueSet variable="case">
      <value value="&quot;immediate&quot;"/>
      <value value="&quot;wait&quot;"/>
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number">
      <value value="10"/>
      <value value="30"/>
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
