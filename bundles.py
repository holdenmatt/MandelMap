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
        filters='coffeescript',

        # Note: these can be eliminated once webassets 0.8 is released.
        output='build/coffee.js',
        debug=False
    ),
    'js/app/Mandelbrot.js',
    filters='uglifyjs',
    output='build/app.js'
)
