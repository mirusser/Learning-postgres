1. Install psql.exe from here: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads (it's a full installer but you can choose to only install Command Line Tools)

![image](https://user-images.githubusercontent.com/14952198/141530400-19b8159d-7ed4-42fd-bff0-15f64169fd3f.png)

2. Open Windows Terminal settings JSON file

![image](https://user-images.githubusercontent.com/14952198/141530467-3b235713-edb6-4b7f-9cbc-9dceaab2d60a.png)

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
