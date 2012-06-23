"""
Define static webasset bundles.
"""
from flask.ext.assets import Bundle


all_css = Bundle(
    'css/bootstrap.css',
    'css/bootstrap-responsive.css',
    'css/TileMap.css',
    filters='cssmin',
    output='build/all.css'
)


# Bundle js libs, except jQuery (loads from CDN) and Modernizr (loads in head).
libs_js = Bundle(
    'js/libs/underscore.js',
    'js/libs/backbone.js',
    'js/libs/bootstrap.js',
    filters='uglifyjs',
    output='build/libs.js'
)

app_js = Bundle(
    Bundle(
        'js/app/TileMap.coffee',
        'js/app/ColorMap.coffee',
        'js/app/Mandelbrot.coffee',
        filters='coffeescript',

        # Note: This will work better in webassets 0.8.
        output='build/coffee.js',
        debug=False
    ),
    filters='uglifyjs',
    output='build/app.js'
)
