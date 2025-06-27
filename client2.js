/*******************************************************************************
Possible new algorithm that does an independent Bernoulli trial each decisecond.
Discussion: http://forum.beeminder.com/t/tagtime-universal-ping-schedule/4143/31
The advantage of this algorithm is that changing the frequency only adds or 
removes pings. If you want to get pinged more (less) often, you get a superset 
(subset) of the pings that someone with a lower (higher) frequency gets.
See the analysis in the forum discussion about whether it's overkill to use 
deciseconds.
*******************************************************************************/

const GAP2 = 45*60       // Average gap between pings, in seconds

const URPING2 = 15338120000 // Birth of the new TagTime algorithm in deciseconds
const SEED2 = 20180809     // Initial state of the random number generator (RNG)
const IA2 = 3125        // (5^5) Multiplier used for LCG RNG
const IM2 = 34359738337 // (2^35-31) Modulus used for RNG (assumes 36-bit ints)
const IAP2 = 1407677000 // =IA^(IM-2)%IM: For rewinding the RNG

// Each decisecond has probability 1/(GAP*10) of being a ping, where GAP is the 
// average time between pings in seconds. The LCG random number generator
// returns a random integer uniformly in {1,...,IM-1} so LCG/IM is a U(0,1) 
// random variable and there's a ping iff 
//   LCG/IM < 1/(GAP*10) => LCG < IM/(GAP*10)
// so we define a constant for the RHS to compare to.
const THRESH = Math.floor(IM2/(GAP2*10));

let state2 = SEED2  // Global variable that's the state of the RNG
let pung2 = URPING2 // Global var with decisecond of last ping

// Return a random integer in [1,IM-1]; changes the RNG state.
// wikipedia.org/wiki/Linear_congruential_generator
function lcg2() { return state2 = IA2 * state2 % IM2; console.log(state2); }

// Compute a*b % m when a*b might exceed Number.MAX_SAFE_INTEGER
function multmod(a, b, m) {
  if (b === 0)   { return 0 }
  if (b%2 === 0) { return multmod(a*2%m, b/2, m) % m }
  else           { return (a + multmod(a, b-1, m)) % m }
}

// Efficiently compute a^n % m -- wikipedia.org/wiki/Modular_exponentiation
function powmod(a, n, m) {
  if (n === 0)   { return 1 }
  let x
  if (n%2 === 0) { x = powmod(a, n/2, m); return multmod(x, x, m) }
  else           { x = powmod(a, n-1, m); return multmod(a, x, m) }
}

// Fast-forward the RNG by doing i steps at once
function powlcg(i) { return state2 = multmod(powmod(IA2, i, IM2), state2, IM2) }

// Same as lcg but in reverse; sets state back to what it was in previous step.
// Also the same as doing powlcg(i) with i equal to the RNG's period minus 1.
function backstep() { return state2 = multmod(IAP2, state2, IM2) }

// Current unixtime in deciseconds
function decinow() { return Math.round(Date.now()/100) }

// Given unixtime in deciseconds, t, start checking at t+1 and return the first
// time we come to with a ping, which becomes the new lastping time.
function nextping2(t) {
  if (t < pung2) { return 0 }         // going back in time not allowed!
  if (t > pung2) { powlcg(t-pung2) }  // fast-forward the RNG up thru t
  pung2 = t+1
  while (lcg2() >= THRESH) { pung2 += 1 }
  return pung2
}

function reset() { [state2, pung2] = [SEED2, URPING2] }

/* 
// Convert seconds to hours/minutes/seconds, like 65 -> "1m5s" or 3600 -> "1h"
// Note that by default this drops seconds. So 65 seconds would be formated as
// just "1m" and even 119s -> "1m" even though that's 1 second shy of 2 minutes.
function genHMS(t, syes=false) { // syes is whether we care about seconds
  if (!isnum(t)) { return 'NaNs' }
  if (t<0) { return '-' + genHMS(-t, syes) }
  t = Math.floor(t) // drop fractions of seconds
  var x = ""
  var h = Math.floor(t/3600)
  t %= 3600
  var m = Math.floor(t/60)
  t %= 60
  if (h>0)                           { x += h+'h' }
  if (m>0 || h>0 && t>0 && syes)     { x += m+'m' }
  if (h===0 && m===0 || t>0 && syes) { x += t+'s' }
  return x
}

// Convenience function. What Jquery's isNumeric does, I guess. Javascript wat?
function isnum(x) { return x - parseFloat(x) + 1 >= 0 }
*/