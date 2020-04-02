# YAIndex
Yet Another Index - prettier replacement for nginx's `autoindex` and apache's
`mod_autoindex`. 

Currently it's set up to only browse the `test_files` directory in the source
repository , but in the future instructions will be provided for using other
folders. 

A demo is deployed on heroku, and can be seen [here](https://yaindex-example.herokuapp.com/)

# Setup
## Deploying yourself
TODO, but the gist is that you want to bind mount the folder you want to view to `/app/test_folder`

## Development
1. Install Docker
1. Clone this repo: `git clone https://github.com/YourFin/yaindex.git && cd yaindex`
1. `docker-compose up`

# How?

Styling is done with [Bulma](https://bulma.io/), and can be found in [app/javascript/styles](./app/javascript/styles)

The current [production dockerfile](/Dockerfile-prod) includes debugging support for heroku; I'll pull this support by adding a separate dockerfile once this is target at being deployable for arbitrary directories.


# Linting
Run `pnpm run lint`. There are multiple different sub lint scripts that
basically do what they seem to, just check out package.json.

# Testing
`pnpm run test`


# Licencing

This software is licenced under Apache 2.0.

The sample images were taken from unsplash, which provides them under no
conditions: https://unsplash.com/license.

Big buck bunny is provided by the Blender Foundation under a Creative-Commons
share-alike licence. Sourced originally from [youtube](https://www.youtube.com/watch?v=aqz-KE-bpKQ).
