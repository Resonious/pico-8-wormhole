# What is this

Modified version of the original [https://github.com/saljam/webwormhole](webwormhole) that instead of sending files, synchronizes the GPIO memory of 2 pico-8 browser carts.

![demo cart - download and export to html](/net_demo.p8.png)

And here is my very lazy ruby script to actually build a pico-8 cart into this project's webpage...

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# put in and run from /home/nigel/.lexaloffle/pico-8/carts

require 'fileutils'

webwormhole_src = ARGV[0] || (raise 'specify webwormhole src in first arg')

FileUtils.cp "#{webwormhole_src}/kalithaz.p8", 'kalithaz.p8'
system '/home/nigel/Sources/pico-8/pico8 kalithaz.p8 -export kalithaz.html'

FileUtils.cp './kalithaz.js', "#{webwormhole_src}/web/cart"

File.open('./kalithaz.html', 'r') do |src|
  File.open("#{webwormhole_src}/web/cart/kalithaz.html", 'w') do |dest|
    src.each_line do |line|
      case line.strip
      when '<!-- Add any content above the cart here -->'
        dest.puts File.read("#{webwormhole_src}/web/cart/top.html")

      when '<!-- Add content below the cart here -->'
        dest.puts File.read("#{webwormhole_src}/web/cart/bottom.html")

      else
        dest.puts line
      end
    end
  end
end

FileUtils.cp "#{webwormhole_src}/web/cart/kalithaz.html",
             "#{webwormhole_src}/web/index.html"
FileUtils.cp "#{webwormhole_src}/web/cart/kalithaz.js",
             "#{webwormhole_src}/web/kalithaz.js"

puts 'Copied!'
```


# Original README

THIS PROJECT IS STILL IN EARLY DEVELOPMENT, IT USES EXPERIMENTAL
CRYPTOGRAPHIC LIBRARIES, AND IT HAS NOT HAD ANY KIND OF SECURITY
OR CRYPTOGRAPHY REVIEWS. BEWARE THIS MIGHT BE BROKEN AND UNSAFE.

	https://xkcd.com/949/

WebWormhole creates ephemeral pipes between computers to send files
or other data. Try it at https://webwormhole.io or on the command
line.

On one computer the tool generates a one-time code for us:

	$ cat hello.txt
	hello, world
	$ ww send hello.txt
	8-enlist-decadence

On another we use the code to establish a connection:

	$ ww receive 8-enlist-decadence
	$ cat hello.txt
	hello, world

To install:

	$ go get webwormhole.io/cmd/ww

Requires Go 1.13.

The author runs an instance of the signalling server that is free to
use at https://webwormhole.io. It comes with no SLAs or any guarantees
of uptime.

To run the signalling server you need to compile the WebAssembly
files first.  Running go generate will execute the appropriate
commands to do that:

	$ go generate ./web
	$ ww server -https= -http=localhost:8000

WebWormhole is inspired by and uses a model very similar to that
of Magic Wormhole. Thanks Brian!

	https://github.com/warner/magic-wormhole

It differs from Magic Wormhole in that it uses WebRTC to make the
direct peer connections. This allows us to make use of WebRTC's NAT
traversal tricks, as well as the fact that it can be used in browsers.
The exchange of session descriptions (offers and answers) is protected
by PAKE and a generated random password, similar to Magic Wormhole.
The session descriptions include the fingerprints of the DTLS
certificates that WebRTC uses to secure its communications.

Unless otherwise noted, the source files in this repository are
distributed under the BSD-style license found in the LICENSE file.
