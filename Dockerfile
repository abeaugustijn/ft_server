# Pull baseimage
FROM 	debian:buster

# Install all packages
RUN		apt -y update &&\
		apt -y upgrade &&\
		apt -y install\
			curl\
			mariadb-server\
			nginx\
			openssl\
			php-cli\
			php-fpm\
			php-mysql\
			php7.3\
			vsftpd\
			wget\
			sudo\
			zsh

# Configure nginx
RUN		mkdir -p /var/www/localhost
COPY	srcs/nginx-config /etc/nginx/sites-available/localhost
RUN		rm -rf /etc/nginx/sites-enabled/*
RUN		ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled

# Generate ssl certificate
RUN		mkdir -p /ssl
RUN		openssl genrsa -out /ssl/localhost.key 2048
RUN		openssl req -new -x509 -key /ssl/localhost.key -out /ssl/localhost.cert\
			-days 3650 -subj /CN=www.localhost

# Download wordpress files
RUN		curl https://wordpress.org/latest.tar.gz -o /var/www/localhost/wp.tar.gz
RUN		tar xzf /var/www/localhost/wp.tar.gz
RUN		mv wordpress /var/www/localhost/wordpress
RUN		rm -f /var/www/localhost/wp.tar.gz
COPY	srcs/wp-config.php /var/www/localhost/wordpress

# Download phpMyAdmin files
RUN		curl https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-english.tar.gz\
			-o /var/www/localhost/php.tar.gz
RUN		tar xzf /var/www/localhost/php.tar.gz
RUN		mv phpMyAdmin-5.0.1-english /var/www/localhost/wordpress/phpmyadmin
RUN		rm /var/www/localhost/php.tar.gz

# Create wordpress database
COPY	srcs/wordpress.sql .
RUN		service mysql start &&\
			cat wordpress.sql | mysql -u root
RUN		rm wordpress.sql

# Install wp-cli
RUN		curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN		chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Add wordpress system user
RUN		adduser --disabled-password --gecos '' wordpress
RUN		sudo adduser wordpress sudo
RUN		chmod -R 777 /var/www/localhost
RUN		chown -R wordpress:wordpress /var/www/localhost

# Install wp core
RUN		service mysql start &&\
	sudo -u wordpress wp core install\
		--path=/var/www/localhost/wordpress\
		--url=localhost\
		--admin_user=wordpress\
		--admin_password=password\
		--admin_email=blabla@blabla.com\
		--title="Totally useful wordpress site!"

# Download latest wordpress plugins
RUN		service mysql start &&\
		sudo -u wordpress\
		wp plugin update --all --allow-root --path=/var/www/localhost/wordpress

# Remove NGINXs' default site
RUN		rm -rf /usr/share/nginx/www

# Set up nginx autoindex configuration
RUN		mkdir /nginx
COPY	srcs/nginx/* /nginx/
COPY	srcs/launch_nginx.sh /nginx/
RUN		chmod +x /nginx/launch_nginx.sh &&\
		mkdir /etc/nginx/locations-enabled

# Set upload limit in php.ini
RUN		echo "upload_max_filesize = 256M\npost_max_size = 256M" >> /etc/php/7.3/fpm/php.ini

# Expose http and https ports
EXPOSE 	80 443 21

# Start services and run a shell
ENTRYPOINT \
	service php7.3-fpm start &&\
	service mysql start &&\
	service vsftpd start &&\
	/nginx/launch_nginx.sh
