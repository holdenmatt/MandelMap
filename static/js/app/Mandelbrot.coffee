###
Mandelbrot.coffee

Render the Mandelbrot set using a CanvasTileMap.

Optionally use a simple method to compute smoothly varying escape times
to produce smooth gradients instead of discrete bands of color.
http://linas.org/art-gallery/escape/escape.html

Question: How should we increase the maxIterations limit as we zoom in?
- At a given zoom level, let's keep track of the distribution of (rounded)
  escape times.
- If we choose maxIterations too large, then we'll spend a lot of computations
  for a very small % of pixels.
- If we choose it too small, a significant % of pixels will be colored black
  that shouldn't be.
- So, let's consider the error
  Err = % of pixels on the canvas that are black but shouldn't be.
- We'd like the smallest maxIterations such that e.g. Err < 0.1%.
- So for each zoom, we'll recalibrate maxIterations to this error level,
  then multiply it by a factor determined heuristically.
###


# Define the colors to use.
COLOR_MAP = ColorMap.RAINBOW

# Start with this value of maxIterations at zoom 0.
INITIAL_MAX_ITERATIONS = 50
maxIterations = INITIAL_MAX_ITERATIONS

# Use a heuristic to increase maxIterations as we zoom in: for each zoom
# first scale maxIterations by this factor...
MAX_ITERATIONS_SCALE_FACTOR = 1.5

# ...then re-calibrate it by lowering it to the lowest value we can without
# losing colors with a % of canvas pixels greater than this % threshold.
MAX_ITERATIONS_ERROR = 0.1

# Use (nearly-)continuous escape times instead of discrete integer values?
USE_SMOOTH_ESCAPE_TIMES = true

# Keep a count of each rounded escape time value (excluding 0) at a given zoom level.
escapeTimeDistribution = {}


# Is a complex point c inside the main cardioid?
isInMainCardioid = (c_x, c_y) ->
    q = (c_x - 0.25) * (c_x - 0.25) + c_y * c_y
    return (q * (q + (c_x - 0.25)) < 0.25 * c_y * c_y)


# Is a point c inside the large bulb of period 2?
isInPeriod2Bulb = (c_x, c_y) ->
    return (c_x + 1) * (c_x + 1) + c_y * c_y < 1 / 16.0


# Iterate until we leave the ball of radius 2, up to the current # of max iterations.
# If we escape after k iterations, return an escape time value (approx. k).
# If we never escape, return 0.
getEscapeValue = (c_x, c_y) ->
    NO_ESCAPE = 0

    # Bypass the escape time computation if we can determine algebraically that
    # we're in the main cardioid or period-2 bulb.
    if isInMainCardioid(c_x, c_y) || isInPeriod2Bulb(c_x, c_y) then return NO_ESCAPE

    # Start at c (after 1 iteration).
    z_x = c_x
    z_y = c_y

    # Iterate until z escapes from the circle of radius 2, or we give up.
    for i in [1...maxIterations]
        x2 = z_x * z_x
        y2 = z_y * z_y

        # Break whenever we leave the ball of radius 2.
        if x2 + y2 > 4
            break

        # Assign z^2 + c -> z.
        z_y = 2 * z_x * z_y + c_y
        z_x = x2 - y2 + c_x

    # Give up, assume no escape.
    if i == maxIterations then return NO_ESCAPE

    if USE_SMOOTH_ESCAPE_TIMES
        # Compute a fractional escape time using the modulus in addition to i.

        # A few more iterations reduces the normalization error.
        extraIterations = 4
        for j in [0...extraIterations]
            x2 = z_x * z_x
            y2 = z_y * z_y
            z_y = 2 * z_x * z_y + c_y
            z_x = x2 - y2 + c_x

        norm = z_x * z_x + z_y * z_y
        modulus = Math.sqrt norm

        # See: http://linas.org/art-gallery/escape/escape.html
        escapeTime = i + extraIterations - Math.log(Math.log(modulus)) / Math.log(2)
    else
        # Using the iteration count as escape time is simpler but produces bands of color.
        escapeTime = i

    # Keep a count for each escape time.
    escapeTimeDistribution[Math.round(escapeTime)]++

    return escapeTime


# Given the current distribution of escape times, return the smallest escape time
# such that larger ones account for only MAX_ITERATIONS_ERROR % of the distribution.
# I.e., we could have used this smaller value of maxIterations without
# any significant visual difference.
recalibrateMaxIterations = () ->
    # Convert raw pixel counts into a percent distribution.
    percents = {}
    sum = 0
    sum += count for time, count of escapeTimeDistribution

    # Sum escape time %s in reverse order until they exceed err.
    times = _.map(_.keys(escapeTimeDistribution), Math.round)

    index = times.length - 1
    totalError = 0
    while index >= 0 and totalError / sum * 100 < MAX_ITERATIONS_ERROR
        time = times[index]
        if time
            totalError += escapeTimeDistribution[time]
        index--

    console.log "Was: " + times[times.length - 1] + " ; Now: " + time
    return time


# Return a color to indicate the escape time at a point.
getColor = (x, y) ->
    value = getEscapeValue(x, y)
    if value == 0
        color = ColorMap.BLACK
    else
        # Shift escape times 1, 2... down to [0, infinity) so we start with color 0.
        value = Math.max(0, value - 1)

        # Apply a sqrt: [0, infinity) -> [0, infinity) before computing colors.
        # Without a transform, we get lots of noise near the M-set, and noise increases
        # as we zoom in.  Applying a sqrt reduces noise, and keeps it constant on zoom.
        value = Math.sqrt value

        # Use the cached color at the nearest tick value.
        index = Math.floor(value * 256) % COLOR_MAP.cache.length
        color = COLOR_MAP.cache[index]
    return color.values


map = new CanvasTileMap
    el: '#map'
    getColor: getColor
    bounds:
        xMin: -2.0
        xMax:  2.0
        yMin: -2.0
        yMax:  2.0

    # Recalibrate maxIterations and reset the distribute on each each zoom.
    beforeZoom: () ->
        maxIterations = Math.round(MAX_ITERATIONS_SCALE_FACTOR * recalibrateMaxIterations 0.1)
        maxIterations = Math.max(maxIterations, INITIAL_MAX_ITERATIONS)
        console.log "New maxIterations: " + maxIterations

        escapeTimeDistribution = {}
        for time in [1..maxIterations]
            escapeTimeDistribution[time] = 0

map.zoomIn()
map.zoomIn()
