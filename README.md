# cf-bluemix-ic
Cloudfoundry container with the IBM Bluemix plugin installed.

bluemix.sh script used for uploading images from wercker to the Bluemix image registry and starting the container in Bluemix. Requires environment variables (shown in the script) to be set in bluemix.

The container has to be uploaded to the relevant bluemix environment as it is consumed by the standard deploy-to-bluemix pipeline stage


# Development
To deploy the built container to bluemix manually follow the instructions [here](https://console.ng.bluemix.net/docs/containers/container_images_pulling.html)

To build locally, use the command

    docker build . -t <registry.DomainName>/<namespace>/<image_name>:<version>
e.g.

    docker build . -t registry.eu-gb.bluemix.net/spconnolly/cf-bluemix-ic:1.0.0


and then push it up to Bluemix

    docker push registry.DomainName/<namespace>/<image

e.g.

    docker push registry.eu-gb.bluemix.net/spconnolly/cf-bluemix-ic:1.0.0
