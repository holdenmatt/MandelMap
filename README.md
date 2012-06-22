# MandelMap

### TileMap

A generic Google-Maps-like interface to view a draggable, zoomable
collection of tiles.

Coordinates, terminology, and interfaces are adapted from the Google Maps API v3:
https://developers.google.com/maps/documentation/javascript/maptypes#MapCoordinates

### Basic Terminology

A _map_ is a container on which tiles are rendered.
This may be e.g. a fractal drawing and not an actual map.

A _tile_ is an HTML element (e.g. an image) to render at a certain position on a map.
All tiles are assumed to be 256x256 pixels.

The _world_ is the entire object we're rendering.


### World Coordinates

Assume the world at zoom level 0 is a single 256x256 pixel tile.

We can parameterize the world with _world coordinates_
using the pixel coordinates on this tile,
with (0, 0) in the top-left corner as expected.
Thus, world coordinates are floating point values (x, y) in
[0, 256] x [0, 256], which are independent of zoom level.


### Pixel Coordinates

World coordinates represent a zoom-independent absolute location in the world.
To determine the correct pixel offset at a given zoom level, we translate these
into _pixel coordinates_ using the formula:
```
pixelCoordinate = worldCoordinate * 2 ^ zoomLevel
```
Note that each successive zoom level is twice as large in each direction as the last.
For example, zoom level 0 is a single tile, zoom level 1 has 4 tiles, etc.
In general, zoom level j has 2^j * 2^j 256-pixel tiles, so each x and y pixel at
this zoom has a value in [0, 256 * 2^j].

Also note that a pixel coordinate's integer part identifies an exact pixel at the
current zoom level.  At zoom level 0, pixel coordinates equal world coordinates.

We can now accurately describe each location on the map, at each zoom level.


### Tiles

Given a viewport center and zoom level, and the map element's size in the DOM,
we can compute the bounding box in pixel coordinates.  So whenever the map is
scrolled or zoomed, we can compute the pixel bounding box and identify which map
tiles are needed to cover the viewport.

Tiles are indexed using x,y coordinates from the same origin as that for pixels.
For example, at zoom level 2, we have 16 tiles indexed by {0,1,2,3} x {0,1,2,3}.

To get the tile coordinate at the current zoom level, just divide the pixel
coordinates by the tile size and take the integer part.


### The getTile interface

A TileMap requires a `getTile` function option, with the following signature:

* `getTile(tileX, tileY, zoom)`

Called whenever we determine the map needs to display the tile at given coordinates
and zoom.  This method should return an HTML element to display as the tile.

* `releaseTile(tile element)`

Called when a map tile needs to be removed.
Use this to handle any clean up like removing event handlers.
