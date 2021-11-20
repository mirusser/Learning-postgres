# Basic shell commands

- quit:
  `\q`
- help:
  `\?`
  `help`
- list all databases:
  `\l`
- clear screen:
  `\! cls`
- connect to a databse (while connected to a server):
  `\c <database>` (e.g. `\c test`)
- show list of relations/tables:
  `\d` (`d` stands for description)
- show table/relation description/details:
  `\d <table>` (e.g. `\d person`)
- show only tables:
  `\dt`
- toggle expanded display (to see results vertically rather than horizontally):
  `\x`
- create file (and open in default text editor (notepad)) with last run query:
  `\e`
- export to csv:
  `\copy (<query>) to '<path>/<filename>.csv' delimiter ',' csv header;`
- list functions:
  `\df`
- run query from file:
  `\i <path>.sql`
