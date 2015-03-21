# docker-gitolite-http

A Dockerfile for [Gitolite](http://gitolite.com/) with added HTTP protocol support. Host your git repositories with Gitolite, access them from anywhere with HTTP ! Uses Apache 2.2, on Debian.

## Usage

<a href="#instructions"></a>
### First installation (if you don't already use Gitolite) :

```bash
# 1. Run the container. Don't bind to the SSH port on the host.
sudo docker run -d --name gitolite-http -p 80:80 -p 8022:22 hyzual/gitolite-http

# 2. Next, create the .htpasswd to enable HTTP access
# Please replace "password" with a more secure password
sudo docker exec gitolite-http htpasswd -cb /data/.htpasswd admin password

# 3. To enable HTTP access to your repository, we first have to access it through SSH
# Copy the private key from the container
sudo docker cp gitolite-http:/data/admin .

# 4. Clone the admin repository, using the copied admin key
# Assuming Docker is installed on localhost
ssh-agent bash -c 'ssh-add ./admin; git clone git@localhost:8022:gitolite-admin'

# 5. Finally, we need to give the R permission to the user daemon (which is Apache).
# Add a "R = daemon" line at the end of the "repo testing" block.
vim gitolite-admin/conf/gitolite.conf

git commit

git push

# 6. Now, test that admin has access to the testing repository through HTTP
# Assuming you redirect to port 80 on localhost
git clone http://admin:password@localhost:80/git/testing

# If you cloned the repository without error, it's a success !
```

### To use existing Gitolite repositories :

First, we'll create a data-only container and we'll fill it with our existing gitolite data and repositories.
You can see those instructions at [gitolite-httpdata](https://registry.hub.docker.com/u/hyzual/gitolite-httpdata/)

```bash
# Create a data-only container which will create the volumes needed
sudo docker run -d --name gitolite-httpdata hyzual/gitolite-httpdata
```

The container will stop immediately, which is normal.

Run another container with bash as command, bind-mount your existing repositories and copy them to the volumes. You will also need to change the permissions in the volume since gitolite-http will run with the image's `git` user. Assuming you already ran gitolite with user `git` on the host :

```bash
# Bind-mount gitolite's data to /hostdata and the repositories to /hostrepo
sudo docker run -it --rm --volumes-from gitolitedata -v /home/git:/hostdata -v /home/git/repositories:/hostrepo hyzual/gitolitedata bash

# Copy from /hostdata to the /data volume, copy from /hostrepo to the /repositories volume and change permissions.
cp -R /hostdata/* /data \
	&& cp -R /hostdata/.gitolite /data \
	&& cp -R /hostdata/.gitolite.rc /data \
	&& chown git:git -R /data \
	&& cp -R /hostrepo/* /repositories \
	&& chown git:git -R /repositories

# Check that the /data and /repositories have correct permissions, then exit from the container
exit
```

Now run gitolite-http with the volumes from our data-only container. Don't bind the SSH port on the host.

```bash
sudo docker run -d --name gitolite-http --p 80:80 -p 8022:22 --volumes-from gitolite-httpdata hyzual/gitolite-http
```

Finally, follow from step 2 the remaining [instructions above](#instructions) to configure the `.htpasswd` file and grant apache access to the repositories.

## Debug :

```bash
# Apache Error log
docker exec gitolite-http cat /var/log/apache2/error.log
# Apache Access log
docker exec gitolite-http cat /var/log/apache2/access.log
# Check apache config
docker exec gitolite-http /usr/sbin/apachectl -t
```

## Volumes

### /data/

`/data/admin.pub` should contain the admin's public key used to access gitolite through ssh. If you don't provide it using the volume, a new rsa key will be generated with that name (along with the private key at `data/admin`).

`/data/.htpasswd` should contain a list of usernames / passwords used to access gitolite through http. The usernames should match existing users of gitolite (i.e. with a public key).

The container will create a symlink from `/data/repositories/` to the `/repositories/` volume when started and Gitolite will create a `/data/projects.list` file.

### /repositories/

`/repositories` will contain the git repositories managed by Gitolite. If you don't provide them using the volume,
 two repositories will be created (as with normal Gitolite installation) :

- `/repositories/gitolite-admin.git/` : the Gitolite administration repository. Use it to add SSH access by providing public keys for people in the `keys/` repository. You can also create new repositories or add read or write access to people using their key's name. See the [Gitolite Documentation](http://gitolite.com/gitolite/gitolite.html#overview) for further information on how to administrate git repositories using Gitolite.
- `/repositories/testing.git/` : a test repository. Use it to test access to Gitolite with HTTP or SSH by cloning it. It's normal if it is empty.

## Ports

### 22

Access Gitolite through SSH using the standard SSH port

### 80

Access Gitolite through HTTP using the standard HTTP port

## Credits

Gitolite's installation steps are heavily borrowed from [aostanin's Gitolite](https://registry.hub.docker.com/u/aostanin/gitolite/), so thanks to him ! Check out his images !
