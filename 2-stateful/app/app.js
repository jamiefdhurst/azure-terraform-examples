/**
 * Module dependencies.
 */

const express = require('express');
const http = require('http');
const path = require('path');

const rangers = require('./routes/rangers'); 
const app = express();

const connection = require('express-myconnection'); 
const mysql = require('mysql');

let initialised = false;

app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(express.json());
app.use(express.urlencoded());

app.use(express.static(path.join(__dirname, 'public')));

app.use(
  connection(mysql, {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USERNAME || 'root',
    password : process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 3306,
    database: process.env.DB_NAME || 'rangers',
    multipleStatements: true,
  }, 'pool')
);

app.use((req, _, next) => {
  req.getConnection((err, conn) => {
    if (!err && !initialised) {
      conn.query(`
        CREATE TABLE IF NOT EXISTS rangers (
          id int(11) NOT NULL AUTO_INCREMENT,
          name varchar(200) NOT NULL,
          PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
        REPLACE INTO rangers (id, name) VALUES (1, 'Red'), (2, 'Black'), (3, 'Yellow'), (4, 'Blue'), (5, 'White');
      `, (err) => {
        if (err) {
          console.error('Error database setup: %s', err);
        } else {
          initialised = true;
        }
        console.log('Initialised database...');
        next();
      });
    } else {
      next();
    }
  });
});

app.get('/', rangers.list);
app.get('/add', rangers.add);
app.post('/add', rangers.addSave);
app.get('/delete/:id', rangers.delete);
app.get('/edit/:id', rangers.edit);
app.post('/edit/:id',rangers.editSave);

http.createServer(app).listen(app.get('port'), () => {
  console.log('Express server listening on port ' + app.get('port'));
});
