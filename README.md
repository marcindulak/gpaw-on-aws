-----------
Description
-----------

This tutorial describes how to configure an HPC (High Performance Computing)
cluster on AWS (Amazon Web Services) using http://aws.amazon.com/hpc/cfncluster/

The flexibility of AWS allows one to use CfnCluster to create one HPC cluster
per research project and manage the cluster from e.g. a laptop computer.
The separation of different project is crucial in order to achieve
reproducible research. Another convenient feature of CfnCluster is auto-scaling,
i.e. when no jobs are in the queue only the Master node is running
(http://cfncluster.readthedocs.org/en/latest/autoscaling.html).

As an example GPAW (https://wiki.fysik.dtu.dk/gpaw/), a materials science code written in Python/C
is run on the cluster using openmpi implementation of MPI (Message Passing Interface).


-----------------------
CfnCluster installation
-----------------------

CfnCluster is written in Python. Virtualenv (https://virtualenv.pypa.io)
is a tool to manage multiple Python-based software stacks on a single machine.

All commands below should be executed as a standard user (**NO** sudo!),
unless explicitly stated.
The standard user prompt is marked by the **$** (dollar) sign.

Install Python Virtualenv and Git with::

  - on Debian/Ubuntu:

        $ sudo apt-get install -y python-virtualenv git

  - on Fedora/CentOS:

        $ su -c "yum -y install python-virtualenv git"

  - on OSX:

    **Warning**: OSX is not research friendly - you will run into troubles!

    You need to install Xcode (https://developer.apple.com/xcode),
    activate it from the terminal, install Command Line Developer Tools,
    and verify that the compilers are present:

        $ sudo xcodebuild -license
        $ sudo xcode-select --install
        $ which llvm-gcc

    Then install Homebrew (that long ruby line at http://brew.sh/)
    and get the necessary tools using brew:

        $ brew install pyenv-virtualenv git
        $ brew doctor

Create the main directory for all virtualenv environments:

    $ mkdir -p ~/Virtualenvs

and initiate your research project virtualenv:

    $ cd ~/Virtualenvs
    $ virtualenv project
    $ cd ~/Virtualenvs/project
    $ . bin/activate

**Note**: you can identify you are in the "project" virtualenv by
the "(project)" appearing on the left of the shell prompt.
In order to exit a given virtualenv do:

    (project)me@laptop:~/Virtualenvs/project$ deactivate

Under an active virtualenv, install CfnCluster:

    (project)me@laptop:~/Virtualenvs/project$ pip install cfncluster

Install also AWS Command Line Interface:

    (project)me@laptop:~/Virtualenvs/project$ pip install awscli

The aws command line tools will be used to copy the [bootstrap.sh](bootstrap.sh) 
software installation script onto AWS S3 (Simple Storage Service).


-----------------
AWS configuration
-----------------

The AWS service are available under your standard Amazon account.
Create one if needed. Note that there is a standing "AWS Free Tier"
offer at https://aws.amazon.com/free/ . You can use it to try out this
tutorial, but you will need to provide credit card details to Amazon
anyway in case of exceeding the free resources pool.

Some steps need to be performed on AWS before you can start using CfnCluster.
The steps are described at http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/get-set-up-for-amazon-ec2.html

**Note** that AWS documentation is unable to keep up with the actual
AWS dashboards - many AWS configuration steps performed in the browser
will involve a bit of guesswork.

   1. login to https://aws.amazon.com/ using you Amazon credentials

   2. create IAM group and user at https://console.aws.amazon.com/iam/ 
      You will use the credentials associated with this users to access the cluster.
      You must **NOT** use you Amazon credentials for daily work on the cluster.
      For the purpose of this tutorial create the "gpaw-on-aws" group and "user1".
      Download the user's credentials (csv file) and store is secretly:

          $ chmod 400 ~/Virtualenvs/project/credentials.csv
      
      Add the user to the "gpaw-on-aws" group. Select the individual
      user and create a password using the "Manage Password" button.
      Write down the https://your_aws_account_id.signin.aws.amazon.com/console/
      available at https://console.aws.amazon.com/iam/ and logout.
   
   3. login as an IAM "user1" at https://your_aws_account_id.signin.aws.amazon.com/console/
      using the password created in the step 2.

   4. as "user1", in the top right corner choose the desirable Region (e.g. Frankfurt == eu-central-1)

   5. as "user1", open EC2 console (top left of the Amazon Web Services dashboard) and
      create key pair named "gpaw-on-aws" and store the automatically downloaded file secretly:

          $ chmod 400 ~/Virtualenvs/project/gpaw-on-aws.pem
       
      The key is bound to the AWS region under which is has been created.

   6. as "user1", create an S3 bucket at https://console.aws.amazon.com/s3/

Note that the IAM users you have created are used only for cluster operations,
and by default they don't have access to administrative information like billing,
which are still handled by your Amazon user.

You are ready to create a cluster using CfnCluster.


----------------
CfnCluster usage
----------------

Under the active "project" virtualenv run cfncluster's captive interface:

    $ cfncluster configure

and answer the questions as described at:
http://cfncluster.readthedocs.org/en/latest/getting_started.html

The AWS Access Key ID, and AWS Secret Access Key ID are those
stored in ~/Virtualenvs/project/credentials.csv

CfnCluster creates by default ~/.cfncluster/config based on the provided
answers with insecure file permissions. Move the file into the virtualenv
and fix the permissions:

    $ ~/Virtualenvs/project
    $ mv ~/.cfncluster/config .
    $ chmod 400 config

We need to customize the config slightly.
See http://cfncluster.readthedocs.org/en/latest/configuration.html for detailed description:

    $ sed -i 's/update_check =.*/update_check = false/' config  # no CfnCluster updates
    $ sed -i '/key_name/acompute_instance_type = t2.micro' config  # compute nodes
    $ sed -i '/key_name/amaster_instance_type = t2.micro' config  # master node
    $ sed -i '/key_name/ainitial_queue_size = 1' config  # initial no. of compute nodes to launch (default 2)
    $ sed -i '/key_name/amax_queue_size = 4' config  # max no. of compute nodes to launch (default 10)
    $ sed -i '/key_name/amaintain_initial_size = false' config  # scale no. of compute nodes down to 0
    $ sed -i '/key_name/ascheduler = sge' config  # the default is sge
    $ sed -i '/key_name/acluster_type = ondemand' config  # spot type is also available - check it out!
    $ sed -i '/key_name/aspot_price = 0.00' config  # spot price
    $ sed -i '/key_name/amaster_root_volume_size = 10' config  # master root / min. size in GB
    $ sed -i '/key_name/acompute_root_volume_size = 10' config  # compute root / min. size in GB
    $ sed -i '/key_name/abase_os = centos6' config  # CentOS 6
    $ echo '[scaling custom]' >> config
    $ echo 'scaling_adjustment = 1' >> config  # default is to add 2 instances

Upload the [bootstrap.sh](bootstrap.sh) script to S3 (see http://cfncluster.readthedocs.org/en/latest/pre_post_install.html):

    $ AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=XXX aws s3 cp --acl public-read --region eu-central-1 bootstrap.sh s3://created-bucket-name/bootstrap.sh

and modify the config file accordingly:

    $ sed -i '/key_name/apost_install = https://created-bucket-name.s3.amazonaws.com/bootstrap.sh' config  # bootstrap

Note that you can host bootstrap.sh on a standard http server instead of S3.

The config provides the template for launching a cluster.
Look at http://cfncluster.readthedocs.org/en/latest/hello_world.html for an example
of launching a cluster, and launch the cluster for your project under the virtualenv:

    $ cfncluster --config config create project

After a couple of minutes you should see the Master instance and
one Compute instance on EC2 dashboard, and after some more time the cfncluster
returns with various information, i.e. about the public IP of the Master (XXX-XXX-XXX-XXX).
You can ssh to the Master using this IP now:

    $ ssh -i gpaw-on-aws.pem ec2-user@XXX-XXX-XXX-XXX

Submit a test [sge.sh](sge.sh) job:

    $ qsub sge.sh
    $ qstat


------------
Dependencies
------------

None


-------
License
-------

BSD 2-clause


----
Todo
----

