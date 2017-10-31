#!/bin/bash
set -eux

mkdir -p tmp/use-npm-repository && cd tmp/use-npm-repository

#
# test the npm repositories.
# see https://help.sonatype.com/display/NXRM3/Node+Packaged+Modules+and+npm+Registries
# see https://docs.npmjs.com/private-modules/ci-server-config
# see https://docs.npmjs.com/cli/adduser

# install node LTS.
# see https://github.com/nodesource/distributions#debinstall
curl -sL https://deb.nodesource.com/setup_6.x | bash
apt-get install -y nodejs
node --version
npm --version

#
# configure npm to use the npm-group repository.

npm config set registry http://localhost:8081/repository/npm-group/

# install a package that indirectly uses the npmjs.org-proxy repository.
mkdir hello-world-npm
pushd hello-world-npm
cat >package.json <<'EOF'
{
  "name": "hello-world",
  "description": "the classic hello world",
  "version": "1.0.0",
  "license": "MIT",
  "main": "hello-world.js",
  "repository": {
    "type": "git",
    "url": "https://git.example.com/hello-world.git"
  },
  "dependencies": {}
}
EOF
cat >hello-world.js <<'EOF'
const leftPad = require('left-pad')
console.log(leftPad('hello world', 40))
EOF
npm install --save left-pad
node hello-world.js


#
# publish a package to the npm-hosted repository.
# see https://www.npmjs.com/package/npm-cli-login

# login.
npm install npm-cli-login
export NPM_USER=alice.doe
export NPM_PASS=password
export NPM_EMAIL=alice.doe@example.com
# NB npm-cli-login always adds the trailing slash to the registry url,
#    BUT npm publish refuses to work without it, so workaround this.
export NPM_REGISTRY=http://localhost:8081/repository/npm-hosted
./node_modules/.bin/npm-cli-login
export NPM_REGISTRY=$NPM_REGISTRY/
npm publish --registry=$NPM_REGISTRY
popd

# publish.
mkdir use-hello-world-npm
pushd use-hello-world-npm
cat >package.json <<'EOF'
{
  "name": "use-hello-world",
  "description": "use the classic hello world",
  "version": "1.0.0",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://git.example.com/use-hello-world.git"
  },
  "dependencies": {}
}
EOF
npm install hello-world
node node_modules/hello-world/hello-world.js
popd
