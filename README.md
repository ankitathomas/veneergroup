# Veneergroups with make

A simple make based solution for managing FBCs and veneers. This requires certain naming conventions to be followed among the input files.

### Variables

This implementation has two input directories and one output directory. These can all be set via the following.

- BINDIR: This is the path to the directory with any special binaries needed to run any steps. There can be versioned or unversioned binaries in this directory. Defaults to `./bin`

An example BINDIR:
```
bin
├── 4.10
│   └── opm
├── 4.11
│   ├── opm
│   └── go
├── 4.X
│   └── docker
└── sh
```

- SRCDIR: The directory from which the veneers, FBCs or other defined versioned sources are read from. Defaults to './pkg'. This does recognize unversioned input files, but it does allow for nesting as long as the version exists somewhere along the relative path.

```
pkg
├── aqua
│   └── 4.10
│       ├── 2022.4.0.channel.yaml
│       ├── 6.5.0.channel.yaml
│       ├── aqua-operator.v2022.4.0.bundle.yaml
│       ├── aqua-operator.v2022.4.1.bundle.yaml
│       ├── aqua-operator.v2022.4.2.bundle.yaml
│       ├── aqua-operator.v6.5.4.bundle.yaml
│       ├── aqua-operator.v6.5.5.bundle.yaml
│       ├── aqua-operator.v6.5.6.bundle.yaml
│       └── package.yaml
├── flux
│   └── 4.11
│       └── flux.veneer.yaml
├── kiali
│   └── 4.X
│       └── kiali.semver.veneer.yaml
└── koku-metrics-operator
    ├── 4.10
    │   └── koku-metrics-operator.semver.veneer.yaml
    └── 4.11
        └── koku-metrics-operator.semver.veneer.yaml
```

- OUTDIR: The directory where the output is stored. This defaults to `./output`. The output preserves the same directory structure as the input; i.e every input file is processed independently as of now.
```
output/
├── 4.10
│   ├── aqua
│   │   ├── 2022.4.0.channel.yaml
│   │   ├── 6.5.0.channel.yaml
│   │   ├── aqua-operator.v2022.4.0.bundle.yaml
│   │   ├── aqua-operator.v2022.4.1.bundle.yaml
│   │   ├── aqua-operator.v2022.4.2.bundle.yaml
│   │   ├── aqua-operator.v6.5.4.bundle.yaml
│   │   ├── aqua-operator.v6.5.5.bundle.yaml
│   │   ├── aqua-operator.v6.5.6.bundle.yaml
│   │   └── package.yaml
│   ├── kiali
│   │   └── kiali.yaml
│   └── koku-metrics-operator
│       └── koku-metrics-operator.yaml
└── 4.11
    ├── flux
    │   └── flux.yaml
    ├── kiali
    │   └── kiali.yaml
    ├── kiali.yaml
    └── koku-metrics-operator
        └── koku-metrics-operator.yaml
```
- VERSION: The version to be built. If no version is given, the FBC for the latest versioned binaries are built.
- FORMAT: This specifies what format the output should be generated in. By default, this is yaml. Caveat: Due to the way already rendered FBCs are preserved, this can lead to mixing of formats. This doesn't affect an FBC's preformance, but can be aesthetically detracting.

### How it works:

There are 3 steps: Generation, validation, commiting

#### Generation
In the generation step, input files are identified by their extensions and processed accordingly. This can be done in parallel if `make` is run with a `-j` argument. There are 3 recognized file extensions with their own rules:
- *.semver.veneer.yaml: Any file with this extension is treated as a semver veneer and is rendered via `opm render-veneer semver`
- *.veneer.yaml: For those files that do not specify themselves as semver veneers, they are treated as basic veneers. `opm render-veneer basic` is run to render these
- *.yaml: These are considered to be already rendered FBCs, and are hence just copied over.

Since FBC does not strictly enforce any specific directory structure, there is no issue with having different parts of the generated FBC in different directories.

#### Validation
Once generation is successful, a set of validation steps may now be applied across the entire generated FBC. Currently, this just runs `opm validate` on the output.

#### Commiting
Until this step, the entire processing is done in a temporary directory. Only FBCs that pass validation successfully get copied to the output location. Once this step is complete, the temporary directory is cleaned up. Otherwise, it is preserved for examination.
