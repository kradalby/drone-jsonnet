# drone-jsonnet

This repo contains the drone.jsonnet files for most of my projects and a
"library" for reusing most of the tasks and pipelines.


## Tooling

There is a bit of "tooling" (scripts really) for updating repos, and they mostly
follow the a convention of:

* All repositories are expected to be in `~/git`
* The name of the repository corresponds with the filename: `REPONAME.jsonnet`


## Kubernetes secrets

`kubernetes.json` contains mappings between repos and namespaces so the correct
namespaces can be queried for secrets. Namespaces is managed by
`[kubespace](https://github.com/kradalby/kubespace)`.
