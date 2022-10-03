# Deployment

## Create charm project and clean

```sh
$ charmcraft init -p charm-redis
```

First is `./src/charm.py`

First we should delete all `observer` function here. We will start deploy from empty class.

Also delete `containers` and `resources` in `metadata.yaml`


## Define container

`metadata.yaml`

Here we define an container name redis, which use resource as it's image.
The redis-image define that we can upload local image use command `--resource redis-iamge=${local_image_path}` when local dev.
Also require a storage mount at `/var/lib/redis`

[details here](https://juju.is/docs/sdk/metadata-reference)

```yaml
...

containers:
  redis:
    resource: redis-image
    mounts:
      - storage: database
        location: /var/lib/redis
resource:
  redis-image:
    type: oci-image
    description: ubuntu lts docker image for redis
    upstream: dataplatformoci/redis:7.0-22.04_edge
storage:
  database:
    type: filesystem
    location: /var/lib/redis
```
