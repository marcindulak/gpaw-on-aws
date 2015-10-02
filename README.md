-----------
Description
-----------

This tutorial describes how to configure an HPC (High Performance Computing)
cluster on AWS (Amazon Web Services) using http://aws.amazon.com/hpc/cfncluster/

The flexibility of AWS allows one to use CfnCluster to create one HPC cluster
per research project and manage the cluster from e.g. a laptop computer.
The separation of different project is crucial in order to achieve
reproducible research. Another convenient feature of CfnCluster is auto-scaling,
i.e. when no jobs are in the queue only the Master node is running,
see http://cfncluster.readthedocs.org/en/latest/autoscaling.html.

As an example GPAW (https://wiki.fysik.dtu.dk/gpaw/), a materials science code written in Python/C
is run on the cluster using openmpi implementation of MPI (Message Passing Interface).
GPAW is benchmarked on various types of AWS instances using a realistic materials science simulation.

All benchmarks in this project were performed in the Frankfurt AWS region (eu-central-1) and summed up to $30 USD.


-----------------------
CfnCluster installation
-----------------------

CfnCluster is written in Python. Virtualenv (https://virtualenv.pypa.io)
is a tool to manage multiple Python-based software stacks on a single machine.

All commands below should be executed as a standard user (**NO** sudo!),
unless explicitly stated.
The standard user prompt is marked by the **$** (dollar) sign.

Install Python Virtualenv with::

  - on Debian/Ubuntu:

        $ sudo apt-get install -y python-virtualenv

  - on Fedora/CentOS:

        $ su -c "yum -y install python-virtualenv"

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

        $ echo 'ARCHFLAGS="-arch x86_64"' >>  ~/.bash_profile
        $ echo 'export PATH=/usr/local/bin:$PATH' >>  ~/.bash_profile
        $ source ~/.bash_profile
        $ brew install python
        $ brew doctor

    Install virtualenv, sadly with pip :(:

        $ pip install virtualenv

    and configure pip to run **only** under virtualenv:

        $ echo 'export PIP_REQUIRE_VIRTUALENV=true' >> ~/.bash_profile
        $ source ~/.bash_profile

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

**Note** that AWS documentation is unable to keep up with the changes to
the AWS dashboards - many AWS configuration steps performed in the browser
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
      create key pair named "gpaw-on-aws-eu-central-1" and store the automatically downloaded file secretly:

          $ chmod 400 ~/Virtualenvs/project/gpaw-on-aws-eu-central-1.pem
       
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
stored in `~/Virtualenvs/project/credentials.csv`.

CfnCluster creates by default `~/.cfncluster/config` based on the provided
answers with insecure file permissions. Move the file into the virtualenv
and fix the permissions:

    $ mv ~/.cfncluster/config .
    $ chmod 400 config

We need to customize the config slightly.
See http://cfncluster.readthedocs.org/en/latest/configuration.html for detailed description:

    $ sed -i 's/update_check =.*/update_check = false/' config  # no CfnCluster updates
    $ sed -i '/key_name/acompute_instance_type = t2.micro' config  # compute nodes
    $ sed -i '/key_name/amaster_instance_type = t2.micro' config  # master node
    $ sed -i '/key_name/ainitial_queue_size = 0' config  # initial no. of compute nodes to launch (default 2)
    $ sed -i '/key_name/amax_queue_size = 4' config  # max no. of compute nodes to launch (default 10)
    $ sed -i '/key_name/amaintain_initial_size = false' config  # scale no. of compute nodes down to 0
    $ sed -i '/key_name/ascheduler = sge' config  # the default is sge
    $ sed -i '/key_name/acluster_type = ondemand' config  # spot type is also available - check it out!
    $ sed -i '/key_name/aspot_price = 0.00' config  # spot price
    $ sed -i '/key_name/amaster_root_volume_size = 10' config  # master root / min. size in GB
    $ sed -i '/key_name/acompute_root_volume_size = 10' config  # compute root / min. size in GB
    $ sed -i '/key_name/abase_os = centos6' config  # CentOS 6
    $ echo '[scaling custom]' >> config
    $ echo 'scaling_threshold = 1' >> config  # default is to scale up when 4 more instances are needed
    $ echo 'scaling_adjustment = 1' >> config  # default is to add 2 instances
    $ echo 'scaling_threshold2 = 200' >> config  # default is to scale up when 200 more instances are needed
    $ echo 'scaling_adjustment2 = 0' >> config  # default is to add 20 instances
    $ echo 'scaling_evaluation_periods = 1' >> config  # default is to use 2 periods

Upload the [bootstrap.sh](bootstrap.sh) script to S3 (see http://cfncluster.readthedocs.org/en/latest/pre_post_install.html):

    $ AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=XXX aws s3 cp --acl public-read --region eu-central-1 bootstrap.sh s3://created-bucket-name/bootstrap.sh

and modify the config file accordingly:

    $ sed -i '/key_name/apost_install = https://created-bucket-name.s3.amazonaws.com/bootstrap.sh' config  # bootstrap

Note that you can host bootstrap.sh on a standard http server instead of S3.

The config provides the template for launching a cluster.
Look at http://cfncluster.readthedocs.org/en/latest/hello_world.html for an example
of launching a cluster, and launch the cluster for your project under the virtualenv:

    $ cfncluster --config config create project

After some waiting time (couple of minutes) you should see the Master instance
on EC2 dashboard, and after some more time the cfncluster
returns with various information, i.e. about the public IP of the Master (XXX-XXX-XXX-XXX).
You can ssh to the Master using this IP now:

    $ ssh -i gpaw-on-aws-eu-central-1.pem ec2-user@XXX-XXX-XXX-XXX

Submit a test [sge.sh](sge.sh) job:

    $ cd /shared  # /shared is on EBS storage
    $ qsub sge.sh
    $ qstat

You can update the settings for the currently running cluster by changing the `config` file and:

    $ cfncluster --config config update project

In order to completely delete the cluster:

    $ cfncluster --config config delete project


-------------
Data handling
-------------

You can store you data on AWS persistent storage, but in case the amount of data is small
mount the AWS storage locally using sshfs:

    $ mkdir -p ~/Virtualenvs/project/shared
    $ sshfs -o idmap=user -o IdentityFile=`readlink -f gpaw-on-aws-eu-central-1.pem` ec2-user@XXX-XXX-XXX-XXX:/shared ~/Virtualenvs/project/shared

You can access the AWS storage this way, e.g. for the purpose of making local backup
or performing local analysis of data. The latter may be necessary as for
September 2015 CfnCluster Master is limited to CentOS 6 images without X.


----------
Benchmarks
----------

EC2 have default resource limit which allows to launch X instances of a give type per region.
The limit can be increased, see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html
however one must be an "established" customer.

The selected GPAW benchmark (see https://wiki.fysik.dtu.dk/gpaw/devel/benchmarks.html#medium-size-system)
consists of 256 water molecules. It requires at least 16 cores with 2GB RAM per core.
The benchmark consists of strong scaling on 16, 32, and 64 CPU cores,
with 16 taken as the reference unit.

Copy the benchmark scripts onto the AWS cluster:

    $ scp -i gpaw-on-aws-eu-central-1.pem -r benchmark ec2-user@XXX-XXX-XXX-XXX:/shared

Login to the Master and submit the benchmark:

    [ec2-user@ip-XXX-XXX-XXX-XXX ]$ cd /shared/benchmark
    [ec2-user@ip-XXX-XXX-XXX-XXX ]$ PATTERN=m4.xlarge sh run.sge.sh

After the calculations finish analyse the results with, e.g.:

    [ec2-user@ip-XXX-XXX-XXX-XXX ]$ python scaling.py -v --dir=m4.xlarge --pattern="m4.xlarge_*_" b256H2O

After collecting all the results perform the analysis with:

    [ec2-user@ip-XXX-XXX-XXX-XXX ]$ sh analyse.sh | grep -v Warning > analyse.txt
    [ec2-user@ip-XXX-XXX-XXX-XXX ]$ python plot.py


---------------------------
Results and cost comparison
---------------------------

The summary of the results is shown on the plot below
and available also as csv file [benchmark/plot.csv](benchmark/plot.csv).
![plot.png](https://raw.github.com/marcindulak/gpaw-on-aws/master/benchmark/plot.png)

The results from various types of AWS instances are compared to the results (labeled as Niflheim) collected on
Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz nodes, 16 CPU cores per node,
connected by an QDR Infiniband network belonging to the https://wiki.fysik.dtu.dk/niflheim/ cluster.
GPAW on AWS is the standard package available in the EPEL repository built against openblas-0.2.14 and openmpi-1.8.1,
while GPAW of Nilfheim uses openblas-0.2.13 and openmpi-1.6.3. Both builds use the same gcc-4.4.7.
Note that the benchmarks were run 3 times, and the best (fastest) run was taken,
due to variations of running time on Linux cluster clusters.

It is difficult to compare the performance of the Niflheim's xeon16 nodes to the AWS instances.
The most similar instance to Niflheim's xeon16 is the m3.2xlarge one, but it has 8 instead of 16 cores and
the cpu clock of 2.5 instead of 2.6 GHz. The performance achieved by m3.2xlarge, even taking into account
that the benchmark on 16 cores involves 2 AWS nodes and single Niflheim node and as such
differs in network usage, is nevertheless surprisingly low compared to Niflheim.

All tested AWS instances with Networking Performance "High",
were measured with iperf to be ~900 Mbit/sec, with ~10% fluctuations,
and show lower strong scaling efficiency than infiniband connected Niflheim's nodes.
The 10 GBit/sec connected AWS instances were not tested.
The CPU performance of the AWS instances (non-burstable ones) shows 5% fluctuations typical for servers running standard Linux.
This together with network instabilities translates into up to 20% (largest seen) of performance fluctuations for multi-node jobs,
which is rather on a high side for a COTS (commercial off-the-shelf) Linux cluster.

For an average GPAW user AWS is not yet an attractive alternative to an ownership of a data center in terms of price.
A typical GPAW project on https://wiki.fysik.dtu.dk/niflheim/ consists of ~256 CPU cores
running continuously over a period of few months. Average single job uses 32 CPU cores. About 100 GBytes of filesystem work storage
(corresponding to AWS EBS) and 1 TByte of archive storage (AWS S3) is used.  

The prices quoted below are for the Frankfurt (eu-central-1) region,
September 27 2015. US regions prices are normally 20% lower.

The storage on AWS will cost (see https://aws.amazon.com/ebs/pricing/ and https://aws.amazon.com/s3/pricing/):
0.119 USD / GB / month * 100 GB + 0.0324 USD / GB / month * 1000 GB ~ 44 USD / month

The compute on AWS would cost (see https://aws.amazon.com/ec2/pricing/), for the c4.4xlarge 16 CPU cores instance is:

- on-demand: 256 / 16 * 24 hour / day * 30 day / month * 1.125 USD / hour = 11520 hour / month * 1.125 USD / hour ~ 13000 USD / month

- reserved instance, 1-year term: 11520 hour / month * 0.7262 USD / hour ~ 8500 USD / month

- reserved instance, 3-year term: 11520 hour / month * 0.523 USD / hour ~ 6000 USD / month

- spot instance: 11520 hour / month * 0.2095 USD / hour ~ 2500 USD / month 

The c4.4xlarge instance (Intel(R) Xeon(R) CPU E5-2666 v3 @ 2.90GHz) turned out to provide
the best performance to cost ratio and therefore selected in the above estimation.
The AWS t2 (burstable) instances cannot be used for production jobs, because their low CPU Credit gets
exceeded quickly and the performance stalls.

On the other hand let's take a hypothetical data center with efficiency of 3.0 PUE
(https://en.wikipedia.org/wiki/Power_usage_effectiveness), running 16 300 Watt servers each costing 5000 USD and
replaced every 50 months, taking the price of kWh to be 0.1 USD. The center is operated by one system administrator
with a monthly salary of 5000 USD, and who shares this task with operating other servers.
This will provide an upper bound to the cost of ownership of a tiny data center.

- the cost of energy per month is: 16 server * 300 Watt / 1000 * kWh / Watt * 3.0 * 700 hour / month * 0.1 USD ~ 1000 USD

- the cost of the hardware per month is: 5000 USD / server * 16 server / 50 month ~ 1600 USD / month

- the cost of administration per month, taking one system administrator operates 100 servers: 5000 USD / 100 * 16 ~ 800 USD

- the costs of of building the server room or hosting the servers physically somewhere are ignored

The total cost of ownership of a tiny, inefficient data center running a single GPAW project is 3500 USD per month.
Thist cost if higher than running the project on Niflheim, and nevertheless about half the price of an AWS cluster
of c4.4xlarge reserved instances run in Frankfurt bound for a 1-year contract, paid upfront.
Taking into account the surprisingly low performance of the c4.4xlarge AWS instances, the cost of running
on AWS is even less attractive.
Note however that the same instances on a 3-year term contract in an US region costs only 4000 USD per month, with
an effective hourly price of c4.4xlarge in N. Virgina is 0.3437 USD / hour / instance.


-----------
Conclusions
-----------

The performance for a realistic GPAW benchmark running the default CentOS 6 RPM available in the
EPEL repository is surprisingly low on AWS.
The most cost effective way of using GPAW on AWS seems to be currently the c4.4xlarge instance
(or, for larger jobs, possibly c4.8xlarge, thanks to it's 10 Gbit/sec networking) run in an US region on a 3-year contract.
In addition to these instances, burstable t2 instances are the most cost effective for performing short tests.

Typical GPAW jobs are running over a period of 2 to 7 days, and GPAW does not currently implement any
usable checkpointing feature. This means one cannot currently use AWS spot instances for GPAW projects.
Implementing a reliable and easy to use checkpointing scheme in GPAW would make AWS spot instances an attractive
alternative to an ownership of a small data center.

Estimating the total cost of ownership of a COTS (components off-the-shelf) Linux data center
is difficult in view of instabilities in performance on the software/hardware side, and
differences in performance depending on the amount of work spent on optimizing the application
for the given hardware platform.
Therefore anyone trying to compare a traditional data center to AWS or other cloud
providers should make the relevant calculations himself.


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

