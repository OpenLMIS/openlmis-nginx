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
Tag for services in Consul's registry to be considered exposed to api gateway. It defaults to `openlmis-service`.

