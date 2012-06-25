###
ColorMap.coffee

A ColorMap is a way of mapping each numeric value in [0, infinity) to a color.
###


# Given start/end values in [0, 255] and a parameter value in [0, 1],
# linearly interpolate from start to end, rounding to an integer.
interpolate = (start, end, param) ->
    value = start + (end - start) * param
    Math.round value


# Represent a color by an array of integer r,g,b,a values in [0, 255].
class Color
    constructor: (@values) ->

    # Linearly interpolate between this color and another one.
    interpolateWith: (other, param) ->
        new Color (interpolate(@values[i], other.values[i], param) for i in [0...4])

    # Convert from a hex code to rgba.
    @fromHex: (hex) ->
        match = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec hex
        if match?
            [r, g, b] = (parseInt(match[i], 16) for i in [1..3])
            new Color [r, g, b, 255]
        else
            throw new Error "Invalid hex code: " + hex


# Represent a linear gradient by color stops at points in [0, 1],
# and linearly interpolate between them in RGBA space.
class LinearGradient

    # Create a gradient from an array of Colors, and optional stop values.
    constructor: (@colors, @stops) ->
        @length = @colors?.length
        if not length >= 2
            throw new Error "At least two Colors are required"

        # Use equal spacing if no stop values are given.
        @stops ?= (i / (@length - 1) for i in [0...@length])
        if @stops.length != @colors.length
            throw new Error "stops and colors must have matching length"

        for i in [0...@length - 1]
            if not 0 <= @stops[i + 1] < @stops[i] <= 1
                throw new Error "stops must be strictly increasing sequence in [0, 1]"

        [first, last] = [@stops[0], @stops[@stops.length - 1]]
        if not (first == 0 and last == 1)
            throw new Error "stops must start with 0 and end with 1"


    # Return the gradient color at a given value in [0, 1].
    colorAt: (value) ->
        if not 0 <= value <= 1
            throw new Error "value must be in [0, 1]"

        # Find the largest index i and smallest index j such that
        # stops[i] <= value <= stops[j].
        i = 0
        while @stops[i + 1] <= value and i + 1 < @length - 1
            i++
        j = @length - 1
        while @stops[j - 1] >= value and j - 1 > 0
            j--

        # Interpolate between the corresponding colors.
        start = @colors[i]
        end   = @colors[j]
        param = if i == j then 0 else (value - @stops[i]) / (@stops[j] - @stops[i])
        return start.interpolateWith end, param


class ColorMap

    constructor: (colors) ->
        # Reflect colors to avoid a hard transition between last/first.
        colors = colors.slice()
        reversed = colors.slice().reverse()
        Array.prototype.push.apply(colors, reversed.slice(1))

        @gradient = new LinearGradient colors
        @period = @gradient.length - 1

        # There can be at most 256 gradient values between each color pair,
        # so cache colors at these tick values.
        @ticks = 256 * @period
        @cache = (@colorAt(val / 256) for val in [0...@ticks])

    colorAt: (value) ->
        # Convert this value to a param in [0, 1] relative to its period.
        param = (value % @period) / @period
        color = @gradient.colorAt param
        return color


ColorMap.RAINBOW = new ColorMap [
    Color.fromHex "#FF0000"
    Color.fromHex "#FFA500"
    Color.fromHex "#FFFF00"
    Color.fromHex "#008000"
    Color.fromHex "#0000FF"
    Color.fromHex "#4B0082"
    Color.fromHex "#EE82EE"
]

ColorMap.BLACK = Color.fromHex "#000000"


window.ColorMap = ColorMap
