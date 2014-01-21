### Linking Docker Containers

It is pretty common to have multiple applications communicate with each other over a network.  You might have a database server that the application server retrieves data from.  In the Docker world, you will create two containers: One for the databsae server and the second one for the application server.

In this tutorial we will demostrate how to setup Docker containers so they can communicate with each other transparently via Links.  Links (since 0.6.5) provides service disocvery for the Docker containers.  There's no need to hardcode the IP address inside  the application that runs in a Docker container.  When you link the containers together Docker will provide the IP address to where the destination container is.  This can also be used as a security feature because, in order for containers to be linked, a name must be specified ahead of time.

I will demostrate Docker Links via a demo RabbitMQ application.  
The topology will consist of three containers:

* RabbitMQ Server
* Message Publisher
* Message Subscriber

We will be using Docker 0.7.2 via Vagrant.  I have created a custom vagrant box file with Docker already preinstalled.  This box file was created from the official Docker's Vagrantfile.

Clone the demo repository and ```cd``` into it:

```git clone TODO_FIX_REPO_NAME``` 

Start up vagrant virtual machine and connect via ssh:

```vagrant up && vagrant ssh```

Make sure /vagrant is properly mounted and should contain all the demo code from the cloned repository.

```cd /vagrant && ls```

```
client1.rb  client2.rb  Dockerfile Gemfile  Vagrantfile
```

#### Build RabbitMQ Server

Let's start by building the RabbitMQ container.  Docker can build it directly from Git:

```docker build -rm -t rabbitmq github.com/forty9ten/docker-rabbitmq```

Since building is complete, you can verify it by listing all the available images:

```docker images```

```
REPOSITORY          TAG                 IMAGE ID            CREATED              VIRTUAL SIZE
rabbitmq            latest              09814f596e4f        About a minute ago   229.6 MB
ubuntu              12.04               8dbd9e392a96        9 months ago         128 MB
```

The image IDs will be different but everything else should be very similar.

#### Build the Clients

Next we will build the clients that will be communicating with RabbitMQ.  The clients are included in this repository so we will instruct Docker to build it from local directory:

```docker build -rm -t rabbitmq_client .```

One again, we can verify by listing the images again:

```docker images```

```
REPOSITORY          TAG                 IMAGE ID            CREATED              VIRTUAL SIZE
rabbitmq_client     latest              4ad59fa07dd1        About a minute ago   834.9 MB
…
…
```

One thing to note is that both clients share the same Docker image since they are both very similar.  When we start the container, we can choose which client we would like to run.

#### Run RabbitMQ Server

Once RabbitMQ has successfully been built, we can run it via command below:

```docker run -name rabbitmq -h rabbitmq -p :49900:15672 rabbitmq```

In order to allow other containers to communicate to the RabbitMQ server, we need to provide a linking name via the **```--name```** option.  **```-h```** is used to specify the hostname of the container.  RabbitMQ uses the hostname to name the log files.  Both the log files and the name of the container is set to **```rabbitmq```**.

You should see RabbitMQ logo and the terminal window will block.

```
              RabbitMQ 3.2.2. Copyright (C) 2007-2013 GoPivotal, Inc.
  ##  ##      Licensed under the MPL.  See http://www.rabbitmq.com/
  ##  ##
  ##########  Logs: /var/log/rabbitmq/rabbit@rabbitmq.log
  ######  ##        /var/log/rabbitmq/rabbit@rabbitmq-sasl.log
  ##########
              Starting broker... completed with 6 plugins.
```

Since we are running RabbitMQ inside Vagrant with no graphical user interface, if we want to see the admin interface for RabbitMQ we need to use the browser on the host machine that is running Vagrant.  This is what the current network topology looks like:

`Host -> Vagrant -> RabbitMQ`

We need to do some port forwarding in order make all three levels of indirections workout.  The included Vagrant file is already port forwarding 49000 to 49900 from the host to Vagrant.  By default, the RabbitMQ admin interface is running on port 15672, so now we need to connect Vagrant port RabbitMQ.  The **`-p`** option specifies port forwarding separated by **`:`** and has the syntax of **`INTERFACE:HOST_PORT:DESTINATION_PORT`**.  We left the interface empty which means it will bind to all interfaces.  The port forwarding looks like below:

`Host:49900 -> Vagrant:49900 -> RabbitMQ:15672`

If everything is setup correctly, we can browse RabbitMQ admin interface from our host browser by going to **`localhost:49900`** (guest/guest)

![RabbitMQ](http://cl.ly/image/221e0p400v1P/RabbitMQ_Management.png =220x150)
#### Run the Clients    

We need to connect two more terminals to vagrant since both apps outputs to stdout while it's running.

Let's start the publisher first (```client1.rb```) 

```docker run -i -t -link rabbitmq:rabbitmq rabbitmq_client client1.rb```

Now the subscriber (```client2.rb```). 

```docker run -i -t -link rabbitmq:rabbitmq rabbitmq_client client2.rb```

If everything goes well, you should see the subcriber output the message counter on the screen.

#### Clean Up

The two RabbitMQ clients can be terminated by sending the Ctrl-C signal.  However, RabbitMQ doesn't trap the signal, so we can stop the container via ```docker stop```. 

```docker stop rabbitmq```

#### Caveat

Links can only be created once.  If you tried to run the container again (even when the container is stopped) you will see the following error:

```
Error: create: Conflict, The name rabbitmq is already assigned to 93f03f024728. You have to delete (or rename) that container to be able to assign rabbitmq to a container again.
```

Behind the scenes, ```docker run``` is composed of two operations: ```create``` and ```start```.  Since it has been created already all we need to do is start the container:

```docker start rabbitmq```


#### Note

All containers can be run in the background without blocking the terminal.  In this tutorial we blocked the terminal for debugging purposes.  We can run in detached mode by passing ```-d``` to ```docker run```.

Notice the RabbitMQ clients are actually running CentOS images, while RabbitMQ server is running Ubuntu.  There is no requirement for what flavor of Linux the containers are running.  It doesn't even have to match the host OS.

 
