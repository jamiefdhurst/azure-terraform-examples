#! /bin/sh

apt-get -y update > /dev/null 2>&1
apt install -y apache2 > /dev/null 2>&1

cat << EOM > /var/www/html/index.html
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Go Go Power Rangers!</title>
  </head>
  <body>
    <div style="text-align: center;">
      <img src="https://upload.wikimedia.org/wikipedia/en/6/61/ZyuRanger1.jpg" />
      <h1 style="font-family: sans-serif; text-align: center;">Mighty Morphin' Power Rangers</h1>
    </div>
  </body>
</html>
EOM
