###
Mandelbrot.coffee

Render the Mandelbrot set using a CanvasTileMap.
###


# Optionally use a simple method to compute smoothly varying escape times
# to produce smooth gradients instead of discrete bands of color.
# http://linas.org/art-gallery/escape/escape.html
USE_SMOOTH_ESCAPE_TIMES = true


# Is a complex point c inside the main cardioid?
isInMainCardioid = (c_x, c_y) ->
    q = (c_x - 0.25) * (c_x - 0.25) + c_y * c_y
    return (q * (q + (c_x - 0.25)) < 0.25 * c_y * c_y)


# Is a point c inside the large bulb of period 2?
isInPeriod2Bulb = (c_x, c_y) ->
    return (c_x + 1) * (c_x + 1) + c_y * c_y < 1 / 16.0


# Iterate until we leave the ball of radius 2, up to a given max # of iterations.
# If we escape after k iterations, return an escape time value (approx. k).
# If we never escape, return 0.
getEscapeValue = (c_x, c_y, maxIterations) ->
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

    # Using the iteration count as escape time is simple but produces bands of color.
    if not USE_SMOOTH_ESCAPE_TIMES then return i

    # We can compute a fractional escape time using the modulus in addition to i.

    # A few more iterations reduces the normalization error.
    extraIterations = 4
    for j in [0...extraIterations]
        x2 = z_x * z_x
        y2 = z_y * z_y
        z_y = 2 * z_x * z_y + c_y
        z_x = x2 - y2 + c_x

    norm = z_x * z_x + z_y * z_y
    modulus = Math.sqrt norm
    normalized = i + extraIterations - Math.log(Math.log(modulus)) / Math.log(2)

    # Ensure the value is >= 1.
    normalized = Math.max(1, normalized);

    return normalized



MAX_ITERATIONS = 100
BLACK = "#000000"


# Return a color to indicate the escape time at a point.
getColor = (x, y) ->
    value = getEscapeValue(x, y, MAX_ITERATIONS)
    if value == 0 then return BLACK

    value = Math.sqrt(value - 1)
    return ColorMap.RAINBOW.colorAt(value).toRGBA()


map = new CanvasTileMap
    el: '#map'
    getColor: getColor
    bounds:
        xMin: -2.0
        xMax:  2.0
        yMin: -2.0
        yMax:  2.0
    # Reset the iteration counts on zoom.
    beforeZoom: () ->
map.zoomIn()
map.zoomIn()
