# YAIndex
Yet Another Index - prettier replacement for nginx's `autoindex` and apache's `mod_autoindex`.

Currently it's set up to only browse the `test_files` directory in this directory, but in the future instructions will be provided for using other folders.

A demo is deployed on heroku, and can be seen [here](https://yaindex-example.herokuapp.com/)

# Setup
## Deploying yourself
TODO, but the gist is that you want to bind mount the folder you want to view to `/app/test_folder`

## Development
1. Install Docker
1. Clone this repo: `git clone https://github.com/YourFin/browser.git && cd browser`
1. `docker-compose run rails bin/initialize.sh`
1. `docker-compose up`

# How?

Currently this application works by running nginx _inside_ the same container as rails, and then reverse proxying all requests to rails except for `/raw/`, which is aliased to the `test_files` directory to serve files directory.

The frontend is written in elm (see [./app/javascript](/app/javascript)), with rails acting as an api.

Styling is done with [Bulma](https://bulma.io/), and can be found in [app/javascript/styles](./app/javascript/styles)

The current [production dockerfile](/Dockerfile-prod) includes debugging support for heroku; I'll pull this support by adding a separate dockerfile once this is target at being deployable for arbitrary directories.

The sample images were taken from unsplash, which provides them royalty free.

# Linting
Run `docker-compose run rails bin/lint.sh`.

Help is available with `docker-compose run rails bin/lint.sh --help`

# Testing
Run `docker-compose run rails bin/test.sh`

Help is available with `docker-compose run rails bin/test.sh --help`

Tests for rails can be found in the [test](./test) directory, while tests for elm can be found in [app/javascript/Tests](./app/javascript/Tests).
The above script automatically runs both.
