# cf-bluemix-ic
Cloudfoundry container with the IBM Bluemix plugin installed.

bluemix.sh script used for uploading images from wercker to the Bluemix image registry and starting the container in Bluemix. Requires environment variables (shown in the script) to be set in bluemix.

The container has to be uploaded to the relevant bluemix environment as it is consumed by the standard deploy-to-bluemix pipeline stage


# Development
To deploy the built container to docker hub or other public registry manually using docker push

To build locally, where namespace is your dockerhub namespace

    docker build . -t <namespace>/<image_name>:<version> ...
e.g.

    docker build . -t stephenconnolly/cf-bluemix-ic:1.0.0 -t stephenconnolly/cf-bluemix-ic:latest


and then push it up to your public registry

    docker push <namespace>/<image>

e.g.

    docker push stephenconnolly/cf-bluemix-ic
