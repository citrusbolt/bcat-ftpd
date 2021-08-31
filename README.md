# bcat-ftpd


---

Config Example (Located on your sd in `sdmc:/config/bcat-ftpd/config.ini`):

```
[TitleID]
titleid:=0x01008DB008C2C000

# titleid:=0x01008DB008C2C000 -> Title ID of the program whose BCAT data you want to access.  Default is Pokémon Shield

[User]
user:=bcat

# user:=bcat -> Login username

[Password]
password:=wonder

# password:=wonder -> Login password

[Port]
port:=6000

# port:=6000 -> opens the server on port 6000 (using the console's IP address).

[Anonymous]
anonymous:=0

# anonymous:=1 -> Allows logging into the ftpd server without username or password.
# anonymous:=0 -> Only allows logging into the ftpd server with the correct username and password. user and password (in fields above) must be set.
```
