1. Install psql.exe from here: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads (it's a full installer but you can choose to only install shell)

2. Open Windows Terminal settings JSON file

3. Add this code (you may have to change the path)

```
{
    "commandline" : "\"%PROGRAMFILES%\\PostgreSQL\\13\\scripts\\runpsql.bat\" -i -l",
    "hidden": false,
    "name": "PostgreSQL"
}
```

usefull links:
https://stackoverflow.com/questions/63259710/add-sql-shell-psql-postgres-to-windows-terminal
https://stackoverflow.com/a/60369228/11613167
