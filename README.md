# openlmis-nginx
Provides dynamic routing and serves as an API Gateway in OpenLMIS environment.

This image is based off of the official nginx image, additionally it provides integration with [Consul](https://www.consul.io/) which serves as a Service Registry for OpenLMIS deployments. [Consul Template](https://github.com/hashicorp/consul-template) is included in this image to be able to work with an external Consul to re-configure Nginx routing based on the Service's registered there.

As Services register themselves with Consul (service registry) directly.  As these registration's occur, this container's Consul Template watches for those changes and reconfigures the routing of the bundled Nginx to match these changes.  This allows Nginx to dynamically route client HTTP requests to Service's that declare they are able to fulfill them.

All services that are tagged with `SERVICE_TAG` are defined as upstreams. Importantly, it also requires a path-service mapping in Consul's Key-Value store (more details in [Path Mapping](#path-mapping) section) to define routes.

Structural Overview:
![alt text](docs/service-discovery-overview.png "Structural Diagram")

## Path mapping
To provide proper route settings, container expects a path-service mapping to be provided. Any endpoints that are not contained within the hierarchy _will not_ be considered as exposed to API gateway. The mapping is expected to be a set of key-value pairs in Consul's Key-Value store, located in `RESOURCES_PATH` subdirectory. For each pair, the key is the (relative) path we want to expose, and the value is the name of our service, so that nginx will assign it to our service's upstream in configuration. If considered path contains a placeholder (such as ID), this should be replaced with `{param}` keyword. Param accepts any valid path that is not already defined in path mapping, but does not match subdirectories. To reserve all addresses under a given path, there is also `<all>` parameter, which will also match all parameters and subdirectories that are not taken.

### Example
For example, lets consider given structure:

users - referencedata  
users/{param} - referencedata  
users/manage - auth  
users/staff/validate - auth  
users/{param}/resetPassword - auth

This will result in following redirections:

/users - referencedata service.  
/users/manage - auth service.  
/users/... - referencedata service.  
/users/.../resetPassword - auth service.  

And importantly:  
/users/staff - referencedata service (as placeholder matches it, and it is not explicitly defined elsewhere).  
/users/staff/validate - auth service.  

## Logging
By default, Nginx logs are stored under `/var/log/nginx` directory, and Consul Template logs can be found in `/var/log/consul-template` folder. Each of those directories is marked as VOLUME and can be mounted to, in order to retrieve logging data. Additionally, user can specify different directories for logging, using `NGINX_LOG_DIR` and `CONSUL_TEMPLATE_LOG_DIR` environment variables.

## Configurable environment variables:
##### `VIRTUAL_HOST`
Name of the server host. It has no default value and must be provided.

##### `CONSUL_HOST`
Server where the Consul instance is running. It defaults to `consul`.

##### `CONSUL_PORT`
Port to contact Consul's API. It defaults to `8500`.

##### `RESOURCES_PATH`
Directory in Consul's Key-Value store where the path hierarchy is located. It defaults to `resources`.

##### `SERVICE_TAG`
When a Service register's itself, it provides a Service Tag property that indicates weather it wants the endpoints it's registering (all of them, no partials) to be exposed to the public and routed to.  The valeu that indicates this is the value that set here as `SERVICE_TAG` when this container is started.  The default is `openlmis-service`.  If this default is used, and a service registers itself with anything other than `openlmis-service`, then that service will not have it's endpoints routed to from Nginx.  This should almost always be left alone, only infrastructure services (e.g. Consul itself) use anything other than `openlmis-service`.

##### `NGINX_LOG_DIR`
The directory to store Nginx log files. It defaults to `/var/log/nginx`.

##### `CONSUL_TEMPLATE_LOG_DIR`
The directory to store Consul Template log files. It defaults to `/var/log/consul-template`.


## Volumes

Two volumes are available which may be used by an outside container to get the logging output from Nginx as well as Consul-Template.

* `/var/log/nginx` - for Nginx logs
* `/var/log/consul-template` for Consul Template

Example:

```
docker volume create --name=nginx-log
docker run -d -v nginx-log:/var/log/nginx --name nginx openlmis/nginx
docker run --rm -v nginx-log:/nginx-log openlmis/dev ls /nginx-log
```

This: 

1. creates a named volume `nginx-log` that nginx will write logs to
2. runs nginx (this image) telling it to mount the named volume `nginx-log` to the nginx logging director
2. runs a throw-away container from the development image that'll mount the named volume `nginx-log` to the path `/nginx-log` and then lists the context of that directory with `ls`.  This third step is just to demonstrate the first 2 steps are working, and instead of listing the contents, one could connect to the name volume and either show the log output to the terminal or this third step could be a container that sends the log contents to an external logging service (e.g. Scalyr)
