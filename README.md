# cf-bluemix-ic
Cloudfoundry container with the IBM Bluemix plugin installed.

bluemix.sh script used for uploading images from wercker to the Bluemix image
registry and starting the container in Bluemix. Requires environment variables
(shown in the script) to be set in bluemix.

The container has to be uploaded to the relevant bluemix environment as it is
consumed by the standard deploy-to-bluemix pipeline stage


# Development
Use the makefile to build, test and push the container.
You must log into docker hub in your shell to create a session
You must also set up the relevant environment variables either in your makefile
or in your environment if you want to test the shell script.
