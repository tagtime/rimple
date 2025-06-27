/*******************************************************************************
The official reference implementation of the TagTime universal ping algorithm is
at http://forum.beeminder.com/t/4282 and this is a copy of that for testing and
experimenting.
*******************************************************************************/

const GAP = 45*60         // Average gap between pings, in seconds
const URPING = 1184097393 // Ur-ping ie the birth of Timepie/TagTime! (unixtime)
const SEED   = 11193462   // Initial state of the random number generator
const IA = 16807          // =7^5: Multiplier for LCG random number generator
const IM = 2147483647     // =2^31-1: Modulus used for the RNG

// Above URPING is in 2007 and it's fine to jump to any later URPING/SEED pair
// like this one in 2018 -- URPING = 1532992625, SEED = 75570 -- without
// deviating from the universal ping schedule.
// URPING = 1536653486
// SEED   = 760042311


let pung = URPING // Global var with unixtime (in seconds) of last computed ping
let state = SEED  // Global variable that's the state of the RNG

//------------------------------------------------------------------------------

// Linear Congruential Generator, returns random integer in {1, ..., IM-1}.
// This is ran0 from Numerical Recipes and has a period of ~2 billion.
function lcg() { return state = IA * state % IM } // lcg()/IM is a U(0,1) R.V.

// Return a random number drawn from an exponential distribution with mean m
function exprand(m) { return -m * Math.log(lcg()/IM) }

//------------------------------------------------------------------------------

// Every TagTime gap must be an integer number of seconds not less than 1
function gap() { return Math.max(1, Math.round(exprand(GAP))) }

//------------------------------------------------------------------------------

// Return unixtime of the next ping. First call init(t) and then call this in
// succession to get all the pings starting with the first one after time t.
function nextping() { return pung += gap() }

// Start at the beginning of time and walk forward till we hit the first ping 
// strictly after time t. Then scooch the state back a step and return the first
// ping *before* (or equal to) t. Then we're ready to call nextping().
function init(t) {
  let p, s          // keep track of the previous values of the global variables
  [pung, state] = [URPING, SEED]                       // reset the global state
  for (; pung <= t; nextping()) { [p, s] = [pung, state] }       // walk forward
  [pung, state] = [p, s]                                        // rewind a step
  return pung                               // return most recent ping time <= t
}

//------------------------------------------------------------------------------



/*
Prototypical usage:

p = init(now)
print "Welcome to TagTime! Last ping would've been at time {p}"
repeat forever:
  p = nextping()
  while now < p: wait
  print "PING!"

*/


/* SCRATCH AREA
state = 1
state = IA * state % IM
let i
for (i = 1; state !== 1; state = IA * state % IM) { i += 1 }
console.log(`i = ${i}`)


Prototypical usage:

p = nextping(now)
q = prevping()
print "Welcome to TagTime! Last ping would've been at time {q}"
repeat forever:
  while now < p: wait
  print "PING!"
  p = nextping(p)


// Start at the beginning of time and walk forward to get the first ping after
// time t. Called as part of nextping if you call it w/ t != previous ping time.
function init(t) {
  for ([pung, state] = [URPING, SEED]; pung <= t; jump()) {}
  return pung
}

// Given unixtime in seconds, t, return the unixtime of the next ping after t.
function nextping(t) { return t !== pung ? init(t) : jump() }

// Rewind the RNG to get the previous ping time; leaves globals unchanged
function prevping() {
  backstep()           // rewinds the global state of the RNG
  return pung - gap()  // gap() bumps RNG state back up as a side effect
}

// Compute a*b % m when a*b may exceed Number.MAX_SAFE_INTEGER
function multmod(a, b, m) {
  if (b === 0)   { return 0 }
  if (b%2 === 0) { return multmod(a*2%m, b/2, m) % m }
  else           { return (a + multmod(a, b-1, m)) % m }
}

// Same as lcg but in reverse; sets state back to what it was in previous step
function backstep() { return state = multmod(IAP, state, IM) }

*/