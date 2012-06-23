###
TileMap.coffee

TileMap:
Manage an interactive Google-Maps-like viewport that can be dragged and zoomed,
and is composed of separate tile elements.

CanvasTileMap:
Use <canvas> tiles that render by progressively enhancing the resolution.
###

# Width/height of tiles, in pixels.
TILE_SIZE = 128

# Tiles are initially rendered with this pixel size, before enhancing.
MIN_RESOLUTION = 16

# Yield to user interaction if we've been drawing more than this # of ms.
ANIMATION_SPEED = 20


# Compare an object's keys against required/optional values.
# Return an error string if any keys are missing or invalid.
validateKeys = (obj, required = [], optional) ->
    keys = _.keys obj
    missing = _.difference required, keys
    if missing.length
        return "Missing required values: " + missing.join ', '

    if optional?
        allowed = _.union required, optional
        invalid = _.difference keys, allowed
        if invalid.length
            return "Invalid values: " + invalid.join ', '


class Model extends Backbone.Model
    initialize: (attrs) ->
        attrs ?= {}
        error = validateKeys attrs, @required, @optional
        if @validate and not error?
            error = @validate attrs
        if error
            throw new Error error

class View extends Backbone.View
    initialize: (options) ->
        @options = _.defaults options || {}, @defaults || {}

        error = validateKeys @options, @required, @optional
        if @validate and not error?
            error = @validate options
        if error
            throw new Error error


# Make a DOM element draggable, even when the mouse is outside the window.
# http://stackoverflow.com/questions/1685326/responding-to-the-onmousemove-event-outside-of-the-browser-window-in-ie
class Draggable extends View
    events:
        mousedown: "mousedown"

    mousedown: (e) =>
        # Remember the location each mousedown/mousemove.
        @lastX = e.clientX
        @lastY = e.clientY

        # Add the move listener, but remove it on mouseup.
        $(document).on "mousemove", @mousemove
        $(document).one "mouseup", (e) =>
            $(document).off "mousemove", @mousemove
            @trigger "dragend"

        @trigger "dragstart"

    mousemove: (e) =>
        # Broadcast the change since we last remember.
        deltaX = e.clientX - @lastX
        deltaY = e.clientY - @lastY
        @trigger "drag", deltaX, deltaY

        @lastX = e.clientX
        @lastY = e.clientY



# Represent a viewport with given pixel dimensions, a zoom level,
# and center x, y (in pixel coordinates).
class Viewport extends Model
    required: ["width", "height"]

    # Start zoomed out and centered.
    initialize: (attrs) ->
        super attrs
        midpoint = TILE_SIZE / 2
        @set
            zoom: 0
            x: midpoint
            y: midpoint

    # Return the bounding box, in pixel coordinates.
    getBounds: () ->
        width = @get "width"
        height = @get "height"
        left = @get("x") - width / 2
        top  = @get("y") - height / 2
        right = left + width
        bottom = top + height
        return [left, right, top, bottom]

    # Find the smallest tile covering for this viewport,
    # returning the array of tile coordinate pairs.
    getCovering: () ->
        # Convert pixel coordinate bounds to tile coordinates.
        [left, right, top, bottom] = @getBounds()
        minX = Math.floor(left / TILE_SIZE)
        maxX = Math.ceil(right / TILE_SIZE)
        minY = Math.floor(top / TILE_SIZE)
        maxY = Math.ceil(bottom / TILE_SIZE)

        tiles = []
        for i in [minX...maxX]
            for j in [minY...maxY]
                tiles.push [i, j]
        return tiles

    setZoom: (zoom) ->
        # Zooming scales pixel coordinates by 2^newZoom / 2^oldZoom.
        delta = zoom - @get "zoom"
        scalar = Math.pow 2, delta
        @set
            x: scalar * @get "x"
            y: scalar * @get "y"
            zoom: zoom

    zoomIn: () ->
        zoom = @get "zoom"
        @setZoom zoom + 1

    zoomOut: () ->
        zoom = @get "zoom"
        if zoom > 0
            @setZoom zoom - 1

    # Translate the viewport by (x, y) in pixel coordinates.
    translate: (x, y) ->
        @set
            x: x + @get "x"
            y: y + @get "y"


class TileMap extends View
    required: ["el", "getTile"]

    validate: (options) ->
        width = @$el.width()
        height = @$el.height()
        if not (width > 0 and height > 0)
            return "el must have nonzero dimensions"

    initialize: (options) ->
        super options

        @$el.css
            position: "relative"
            background: "#E5E3DF"
            overflow: "hidden"

        @width = @$el.width()
        @height = @$el.height()

        @viewport = new Viewport
            width: @width
            height: @height

        # Update the tile container when the viewport changes.
        @viewport.on "change", @updateOffset

        # Keep track of which tiles are currently visible,
        # indexed by tile coordinates.
        @tiles = {}

        @createTileContainer()
        @createZoomControl()

        @updateOffset()
        @render()

    # Create a draggable container for tiles.
    createTileContainer: () ->
        @tileContainer = new Draggable
        @tileContainer.$el.css
            width: "100%"
            height: "100%"
        .appendTo @el

        # Update the viewport on drag.
        @tileContainer.on "drag", (deltaX, deltaY) =>
            @viewport.translate -deltaX, -deltaY

        # Request tiles when a drag ends.
        @tileContainer.on "dragend", @render

    # Create control buttons to zoom in and out.
    createZoomControl: () ->
        @zoomControl = $(
            """
            <div class="zoom-control">
                <div class="top button"><div class="plus icon"></div></div>
                <div class="bottom button"><div class="minus icon"></div></div>
            </div>
            """
        ).appendTo @el
        @zoomControl.on "click", ".top", @zoomIn
        @zoomControl.on "click", ".bottom", @zoomOut

    # Update the tile container offset to the current viewport.
    updateOffset: () =>
        [left, right, top, bottom] = @viewport.getBounds()
        [offsetX, offsetY] = [-left, -top]
        @tileContainer.$el.css
            WebkitTransform: "translate3d(#{offsetX}px, #{offsetY}px, 0)"

    # Add a tile at given tile coordinates, removing any existing tile.
    addTile: (tile, tileX, tileY) ->
        @removeTile tileX, tileY
        key = "#{tileX},#{tileY}"
        @tiles[key] = tile
        $(tile).css
            position: "absolute"
            left: tileX * TILE_SIZE
            top:  tileY * TILE_SIZE
            width: TILE_SIZE
            height: TILE_SIZE
            WebkitUserSelect: "none"
        .appendTo(@tileContainer.el)

    # Remove the tile at given tile coordinates, if any.
    removeTile: (tileX, tileY) ->
        key = "#{tileX},#{tileY}"
        tile = @tiles[key]
        if tile?
            @options.releaseTile?(tile)
            $(tile).remove()
            delete @tiles[key]

    # Remove all tiles.
    clearTiles: () ->
        for key of @tiles
            [tileX, tileY] = key.split(',')
            @removeTile tileX, tileY

    zoomIn: () =>
        @options.beforeZoom?()
        @viewport.zoomIn()
        @clearTiles()
        @render()
    zoomOut: () =>
        if @viewport.get("zoom") > 0
            @options.beforeZoom?()
            @viewport.zoomOut()
            @clearTiles()
            @render()

    # Get and add the tiles needed to cover the current viewport.
    render: () =>
        zoom = @viewport.get "zoom"
        for [tileX, tileY] in @viewport.getCovering()
            tile = @options.getTile tileX, tileY, zoom
            @addTile tile, tileX, tileY



# Extend TileMap to use <canvas> tiles.
# Use a drawing queue to render tiles with progressively enhanced resolutions.
class CanvasTileMap extends TileMap
    required: ["el", "getColor", "bounds"]

    render: () =>
        # Use a queue to represent tiles needed (including resolution).
        # Clear the queue on each render.
        @tileQueue = []

        zoom = @viewport.get "zoom"
        for [tileX, tileY] in @viewport.getCovering()
            # See if we already have a tile here.
            key = "#{tileX},#{tileY}"
            tile = @tiles[key]
            if tile?
                # Skip lower resolutions if we already have a tile.
                resolution = tile.resolution / 2
            else
                resolution = MIN_RESOLUTION

            # Enqueue this tile/zoom/resolution for rendering.
            if resolution >= 1
                @tileQueue.push
                    tileX: tileX
                    tileY: tileY
                    zoom: zoom
                    resolution: resolution

        @renderNextTiles()

    # Render the next tiles in the queue, pausing for user interaction
    # after a specified threshold.
    renderNextTiles: () =>
        start = current = (new Date).getTime()
        while current - start < ANIMATION_SPEED
            next = @tileQueue.shift()
            if not next?
                break

            tile = @getTile next.tileX, next.tileY, next.zoom, next.resolution
            tile.resolution = next.resolution
            @addTile tile, next.tileX, next.tileY

            # Re-enqueue the same tile with a higher resolution.
            if next.resolution > 1
                next.resolution = next.resolution / 2
                @tileQueue.push next

            current = (new Date).getTime()

        if @tileQueue.length > 0
            setTimeout @renderNextTiles, 0

    # Return a canvas tile for the given tile coordinates, zoom,
    # and resolution (i.e. pixel width).
    getTile: (tileX, tileY, zoom, resolution) =>

        tile = $('<canvas>').attr
            width: TILE_SIZE + 'px'
            height: TILE_SIZE + 'px'

        context = tile.get(0).getContext('2d')
        bounds = @options.bounds

        for i in [0...TILE_SIZE] by resolution
            for j in [0...TILE_SIZE] by resolution

                # Convert pixel center to pixel coordinates.
                pixelX = tileX * TILE_SIZE + i + resolution / 2.0
                pixelY = tileY * TILE_SIZE + j + resolution / 2.0

                # Convert pixel coordinates to world coordinates.
                worldX = pixelX * Math.pow(2, -zoom)
                worldY = pixelY * Math.pow(2, -zoom)

                # Convert world coordinates to user coordinates.
                x = bounds.xMin + (bounds.xMax - bounds.xMin) * worldX / TILE_SIZE
                y = bounds.yMin + (bounds.yMax - bounds.yMin) * worldY / TILE_SIZE

                context.fillStyle = @options.getColor(x, y)
                context.fillRect(i, j, resolution, resolution)

        return tile


window.TileMap = TileMap
window.CanvasTileMap = CanvasTileMap
