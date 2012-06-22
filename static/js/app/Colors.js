//
// Colors.js
//
// Map numeric values [0, infinity) to colors.
//
window.Colors = (function () {
    var Colors = {};

    var msgCount = 0,
        printed = 0;
    function log() {
        if (printed < 1000) {
            msgCount++;
            if (msgCount % 1000 === 0) {
                printed++;
                console.log(arguments);
            }
        }
    }

    var BLACK = "#000000";
    var RAINBOW = [
        "#FF0000",
        "#FFA500",
        "#FFFF00",
        "#008000",
        "#0000FF",
        "#4B0082",
        "#EE82EE"
    ];

    // Map 1, 2, 3... by cycling an array of colors.
    Colors.cycle = function (value, colors) {
        if (value === 0) {
            return BLACK;
        }

        // Use rainbow colors by default.
        colors = colors || RAINBOW;

        var index = (Math.floor(value) - 1) % colors.length;
        return colors[index];
    };

    // Linearly map [0, 1] -> [min, max].
    function interpolateValue (value, min, max) {
        return min + value * (max - min);
    }

    // Linearly map [0, 1] to a gradient, using a sequence of N colors.
    function interpolateColor (value, colors) {
        if (!(0 <= value && value <= 1)) {
            throw new Error('value out of range');
        }
        if (colors.length < 2) {
            throw new Error('At least 2 colors are required');
        }

        if (colors.length === 2) {
            // Just interpolate rgb values.
            var color1 = colors[0],
                color2 = colors[1];
            return {
                r: Math.floor(interpolateValue(value, color1.r, color2.r)),
                g: Math.floor(interpolateValue(value, color1.g, color2.g)),
                b: Math.floor(interpolateValue(value, color1.b, color2.b))
            };
        } else if (colors.length > 2) {

            // Map [0, 1] -> [0, N - 1] and get upper/lower integers.
            var scaled = value * (colors.length - 1),
                upper  = scaled === 0 ? 1 : Math.ceil(scaled),
                lower  = upper - 1;

            // Interpolate between just this pair of upper/lower colors.
            return interpolateColor(scaled - lower, colors[lower], colors[upper]);
        }
    }

    // Map [1, infinity) by smoothly interpolating an array of N colors.
    Colors.interpolate = function (value, colors) {
        if (value === 0) {
            return BLACK;
        }

        colors = colors || [
            {
                r: 255,
                g: 0,
                b: 0
            },
            {
                r: 0,
                g: 0,
                b: 255
            }
        ];

        // High values tend to get close together quickly.
        // Slow this down so we can see the variation better.
        value = Math.sqrt(value);

        // Map [1, infinity) -> (0, 1].
        value = 1 / value;

        var color = interpolateColor(value, colors);
        return 'rgb(' + color.r + ', ' + color.g + ', ' + color.b + ')';
    };

    return Colors;
})();
