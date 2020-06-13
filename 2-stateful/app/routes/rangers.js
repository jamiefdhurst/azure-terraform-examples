exports.list = (req, res) => {
  req.getConnection((_, conn) => {
    conn.query('SELECT * FROM rangers', (err, rows) => {
      if (err) {
        console.error('Error selecting: %s', err);
      }
      res.render('list', {
        pageTitle: 'Power Rangers',
        data: rows
      });
    });
  });
};

exports.add = (_, res) => {
  res.render('add', {
    pageTitle: 'Power Rangers - Add'
  });
};

exports.edit = (req, res) => {
  const id = req.params.id;
  req.getConnection((_, conn) => {
    conn.query('SELECT * FROM rangers WHERE id = ?', [id], (err, rows) => {
      if (err) {
        console.error('Error selecting single: %s', err);
      }
      res.render('edit', {
        pageTitle: 'Power Rangers - Edit',
        data: rows
      });
    });
  });
};

exports.addSave = (req, res) => {
  req.getConnection((_, conn) => {
    conn.query('INSERT INTO rangers SET ?', {name: req.body.name}, (err) => {
      if (err) {
        console.error('Error inserting: %s', err);
      }
      res.redirect('/');
    });
  });
};

exports.editSave = (req, res) => {
  const id = req.params.id;
  req.getConnection((_, conn) => {
    conn.query('UPDATE rangers SET ? WHERE id = ?', [{name: req.body.name}, id], (err) => {
      if (err) {
        console.error('Error updating: %s', err);
      }
      res.redirect('/');
    });
  });
};
    
exports.delete = (req, res) => {
  const id = req.params.id;
  req.getConnection((_, conn) => {
    conn.query('DELETE FROM rangers WHERE id = ?', [id], (err) => {
      if (err) {
        console.error('Error deleting: %s', err);
      }
      res.redirect('/');
    });
  });
};
