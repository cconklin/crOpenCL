# crOpenCL [![Build Status](https://travis-ci.org/cconklin/crOpenCL.svg?branch=master)](https://travis-ci.org/cconklin/crOpenCL)

OpenCL Bindings fo Crystal

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  crOpenCL:
    github: cconklin/crOpenCL
```

Currently only supports Mac OS


## Usage


```crystal
require "crOpenCL"
```

## Issues

1. Can't develop tests to verify the interaction with the C libs, as mocks don't support it yet.

## Contributing

1. Fork it ( https://github.com/[your-github-name]/crOpenCL/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [cconklin](https://github.com/cconklin) Chase Conklin - creator, maintainer
