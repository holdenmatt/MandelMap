/*
 Mandelbrot.js

 Given a complex constant c = c_x + c_y i, start at z = 0 and iterate the
 quadratic recurrence function z^2 + c -> z
 until we leave the ball of radius 2 (which implies the process escapes
 to infinity) or until we give up (after maxIterations).
*/
(function () {

    var MAX_ITERATIONS = 100;

    var BLACK = "#000000";

    // Is a complex point c inside the main cardioid?
    function isInMainCardioid (c_x, c_y) {
        var q = (c_x - 0.25) * (c_x - 0.25) + c_y * c_y;
        return (q * (q + (c_x - 0.25)) < 0.25 * c_y * c_y);
    }

    // Is a point c inside the large bulb of period 2?
    function isInPeriod2Bulb (c_x, c_y) {
        return (c_x + 1) * (c_x + 1) + c_y * c_y < 1/16.0;
    }

    // Iterate until we leave the ball of radius 2, up to a given max # of iterations.
    // If we never escape, return 0.
    // If we escape after k iterations, return an escape time value >= 1 (and approx. k).
    function getEscapeValue (c_x, c_y, maxIterations) {
        var z_x, z_y, x2, y2, norm, i;

        var NO_ESCAPE = 0;

        // Bypass the escape time computation if we can determine algebraically that
        // we're in the main cardioid or period-2 bulb.
        if (isInMainCardioid(c_x, c_y) || isInPeriod2Bulb(c_x, c_y)) {
            return NO_ESCAPE;
        }

        // Start at c (after 1 iteration).
        z_x = c_x;
        z_y = c_y;

        // Iterate until z escapes from the circle of radius 2, or we give up.
        for (i = 1; i < maxIterations; i++) {
            // Compute the norm.
            x2 = z_x * z_x;
            y2 = z_y * z_y;

            if (x2 + y2 < 4) {
                // Compute z^2 + c -> z
                z_y = 2 * z_x * z_y + c_y;
                z_x = x2 - y2 + c_x;
            } else {
                // Break whenever we leave the ball of radius 2.
                break;
            }
        }

        if (i < maxIterations) {
            // Use this technique to compute a continuous fractional escape time:
            // http://linas.org/art-gallery/escape/escape.html

            // Iterating a couple more times reduces the normalization error.
            var moreTerms = 4;
            for (var j = 0; j < moreTerms; j++) {
                x2 = z_x * z_x;
                y2 = z_y * z_y;
                z_y = 2 * z_x * z_y + c_y;
                z_x = x2 - y2 + c_x;
            }

            var modulus = Math.sqrt(z_x * z_x + z_y * z_y),
                normalized = i + moreTerms - Math.log(Math.log(modulus)) / Math.log(2);

            // Ensure the value is >= 1.
            normalized = Math.max(1, normalized);

            return normalized;
        } else {
            return NO_ESCAPE;
        }
    }

    // Return a color to indicate the escape time at a point.
    function getColor (x, y) {
        var value = getEscapeValue(x, y, MAX_ITERATIONS);
        if (value === 0) {
            return BLACK;
        }
        return ColorMap.RAINBOW.colorAt(value - 1).toHex();
    }

    var map = new CanvasTileMap({
        el: '#map',
        getColor: getColor,
        bounds: {
            xMin: -2.0,
            xMax:  2.0,
            yMin: -2.0,
            yMax:  2.0
        },
        // Reset the iteration counts on zoom.
        beforeZoom: function () {

        }
    });
    map.zoomIn();
    map.zoomIn();
})();
