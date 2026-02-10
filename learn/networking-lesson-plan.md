# Networking Lesson Plan

A progressive curriculum to understand computer networking by sending packets
and inspecting what happens on the wire.

## Lesson 1: The Network Stack

**Goal:** Understand the layered model that makes networking work and see the
layers in action.

### Concepts

Networks are organized in layers -- each layer handles one concern and passes
data to the next. The TCP/IP model has four layers: link (Ethernet, Wi-Fi),
internet (IP), transport (TCP, UDP), and application (HTTP, DNS). When you type
a URL, your browser resolves DNS, opens a TCP connection, sends an HTTP request,
and reads the response -- each step handled by a different layer. The `curl -v`
flag reveals this entire stack in one command.

### Exercises

1. **See the stack with curl**

   ```bash
   curl -v https://example.com 2>&1 | head -30
   # * Trying 93.184.216.34:443...     <- IP layer (resolved address)
   # * Connected to example.com         <- TCP layer (connection established)
   # * SSL connection using TLS 1.3     <- Security layer
   # > GET / HTTP/2                     <- Application layer (HTTP request)
   ```

2. **Trace the DNS and TCP steps separately**

   ```bash
   # Step 1: Resolve the name to an IP address
   dig +short example.com

   # Step 2: Test TCP connectivity to that IP
   nc -vz example.com 80

   # Step 3: Send an HTTP request manually
   echo -e "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" | nc example.com 80 | head -20
   ```

3. **Inspect HTTP headers**

   ```bash
   curl -sI https://example.com
   # -s = silent, -I = HEAD request (headers only)
   # Note: Status line, Content-Type, Content-Length, Date
   ```

4. **Map each layer to a tool**

   ```bash
   # Link/Physical: see your network interfaces
   ifconfig en0 | head -5

   # Internet: trace the IP route to a host
   traceroute -m 5 example.com

   # Transport: see active TCP connections
   lsof -i -n -P | grep ESTABLISHED | head -10

   # Application: fetch an HTTP resource
   curl -s https://example.com | head -5
   ```

### Checkpoint

Run `curl -v https://example.com` and annotate each line of output with the
network layer it belongs to. Identify the DNS resolution, TCP handshake, TLS
negotiation, and HTTP exchange.

---

## Lesson 2: DNS

**Goal:** Understand how domain names resolve to IP addresses and how to
interrogate the DNS system.

### Concepts

DNS is a distributed hierarchical database that maps names to records. A query
for `example.com` starts at a root server, walks to the `.com` TLD server, then
to the authoritative server for `example.com`. Common record types include A
(IPv4 address), AAAA (IPv6), CNAME (alias), MX (mail server), and TXT (arbitrary
text, often used for verification). Your machine caches DNS results according to
each record's TTL.

### Exercises

1. **Query DNS records**

   ```bash
   # A record (IPv4)
   dig example.com A +short

   # AAAA record (IPv6)
   dig example.com AAAA +short

   # MX record (mail servers)
   dig google.com MX +short

   # TXT records (SPF, DKIM, verification)
   dig google.com TXT +short
   ```

2. **Trace the full resolution path**

   ```bash
   # Walk the hierarchy from root servers
   dig example.com +trace

   # Use nslookup for a simpler view
   nslookup example.com

   # Query a specific DNS server
   dig @8.8.8.8 example.com A +short
   ```

3. **Edit local DNS with /etc/hosts**

   ```bash
   # View your hosts file
   cat /etc/hosts

   # Add a local override (requires sudo)
   # sudo sh -c 'echo "127.0.0.1 mytest.local" >> /etc/hosts'
   # ping mytest.local

   # Use dscacheutil to verify macOS resolution
   dscacheutil -q host -a name mytest.local
   ```

4. **Flush and inspect the DNS cache**

   ```bash
   # macOS: flush DNS cache
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

   # Resolve a name and check the TTL
   dig example.com | grep -E "^example"
   # The number after the name is the TTL in seconds

   # Check CNAME chains
   dig www.github.com CNAME +short
   dig www.github.com A +short
   ```

### Checkpoint

Use `dig +trace` to resolve a domain and identify each step: root server, TLD
server, authoritative server, final answer. Then add a custom entry to
`/etc/hosts`, verify it resolves with `dscacheutil`, and remove it when done.

---

## Lesson 3: TCP and UDP

**Goal:** Understand connection-oriented vs connectionless transport and observe
both protocols in action.

### Concepts

TCP provides reliable, ordered delivery -- the three-way handshake (SYN,
SYN-ACK, ACK) establishes a connection before data flows. TCP retransmits lost
packets and enforces flow control. UDP skips the handshake and sends datagrams
with no delivery guarantee, making it faster for real-time applications like DNS
queries, video, and games. Every connection is identified by a tuple of source
IP, source port, destination IP, and destination port.

### Exercises

1. **Observe the TCP handshake**

   ```bash
   # Start a TCP listener in one terminal
   nc -l 9999

   # Connect from another terminal
   nc localhost 9999

   # While connected, observe the established connection
   lsof -i :9999 -n -P
   # You will see LISTEN and ESTABLISHED states

   # Type messages in either terminal -- they appear in the other
   # Ctrl-C to close
   ```

2. **Send and receive UDP datagrams**

   ```bash
   # Start a UDP listener
   nc -u -l 9999

   # In another terminal, send UDP datagrams
   echo "hello via UDP" | nc -u localhost 9999

   # Note: no handshake, no connection state
   # The listener prints the message immediately
   ```

3. **Inspect connection states**

   ```bash
   # See all active network connections
   netstat -an | head -30

   # Filter for a specific port
   lsof -i :443 -n -P | head -10

   # Watch connections in real time
   lsof -i -n -P | grep ESTABLISHED | head -15

   # See connection states (LISTEN, ESTABLISHED, TIME_WAIT)
   netstat -an | grep -E "LISTEN|ESTABLISHED|TIME_WAIT" | head -15
   ```

4. **Explore well-known ports**

   ```bash
   # Common ports: 22 (SSH), 53 (DNS), 80 (HTTP), 443 (HTTPS)
   # Test connectivity to several services
   nc -vz google.com 80
   nc -vz google.com 443
   nc -vz google.com 22

   # See what is listening on your machine
   lsof -i -n -P | grep LISTEN
   ```

### Checkpoint

Start a TCP listener with `nc -l 9999`. Connect to it from another terminal. Use
`lsof -i :9999` to confirm the connection is ESTABLISHED. Send a message through
the connection, then close it and observe TIME_WAIT state.

---

## Lesson 4: HTTP as a Network Protocol

**Goal:** See HTTP as a text protocol that rides on TCP and understand its
mechanics at the wire level.

### Concepts

HTTP is a request-response protocol layered on top of TCP. The client sends a
method, path, headers, and optional body; the server responds with a status
code, headers, and body. The `curl -v` trace shows TCP connection setup, the raw
request, and the raw response. HTTP/1.1 introduced keep-alive (reuse the TCP
connection for multiple requests). HTTP/2 multiplexes streams over a single
connection with binary framing.

### Exercises

1. **Trace a full HTTP exchange**

   ```bash
   curl -v http://example.com 2>&1
   # Lines starting with > are the request
   # Lines starting with < are the response
   # Note: Connection, Host, Content-Type headers
   ```

2. **Manually send HTTP with netcat**

   ```bash
   # Send a raw HTTP/1.1 request
   printf "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n" | \
     nc example.com 80

   # Observe: status line, headers, blank line, body
   # The blank line (\r\n\r\n) separates headers from body
   ```

3. **Observe keep-alive vs close**

   ```bash
   # HTTP/1.1 defaults to keep-alive
   curl -v --http1.1 http://example.com http://example.com 2>&1 | \
     grep -E "Connected|Re-using|Closing"

   # Explicit Connection: close
   curl -v -H "Connection: close" http://example.com 2>&1 | \
     grep -E "Connected|Closing"
   ```

4. **Compare HTTP/1.1 and HTTP/2**

   ```bash
   # HTTP/1.1
   curl -v --http1.1 https://example.com 2>&1 | grep -E "^[<>] |HTTP/"

   # HTTP/2 (binary framing -- curl shows decoded frames)
   curl -v --http2 https://example.com 2>&1 | grep -E "^[<>] |HTTP/"

   # Check if a server supports HTTP/2
   curl -sI --http2 https://example.com | head -1
   ```

### Checkpoint

Use `nc` to manually send an HTTP request to `example.com`. Parse the response
by hand: identify the status line, each header, the blank separator, and the
body. Then compare the same request via `curl -v` and confirm the fields match.

---

## Lesson 5: Sockets

**Goal:** Write network programs using the socket API -- the fundamental
interface between your code and the TCP/IP stack.

### Concepts

A socket is an endpoint for network communication, identified by an IP address
and port. The server calls `bind()`, `listen()`, and `accept()` to wait for
connections. The client calls `connect()` to reach the server. Once connected,
both sides use `send()` and `recv()` to exchange data. Sockets work for both TCP
(SOCK_STREAM) and UDP (SOCK_DGRAM). Understanding sockets reveals what libraries
like `requests` and `http.server` do under the hood.

### Exercises

1. **Build a TCP echo server**

   ```python
   # echo_server.py
   import socket

   server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
   server.bind(("127.0.0.1", 9999))
   server.listen(1)
   print("Listening on 127.0.0.1:9999")

   conn, addr = server.accept()
   print(f"Connection from {addr}")
   while True:
       data = conn.recv(1024)
       if not data:
           break
       print(f"Received: {data.decode()}")
       conn.sendall(data)  # Echo it back
   conn.close()
   server.close()
   ```

   ```bash
   python3 echo_server.py &
   # In another terminal:
   echo "hello" | nc localhost 9999
   ```

2. **Build a TCP client**

   ```python
   # echo_client.py
   import socket

   sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   sock.connect(("127.0.0.1", 9999))
   sock.sendall(b"Hello from client\n")
   response = sock.recv(1024)
   print(f"Server replied: {response.decode()}")
   sock.close()
   ```

   ```bash
   # Start the echo server first, then:
   python3 echo_client.py
   ```

3. **Build a UDP sender and receiver**

   ```python
   # udp_receiver.py
   import socket

   sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   sock.bind(("127.0.0.1", 9998))
   print("Waiting for UDP datagrams on :9998")
   data, addr = sock.recvfrom(1024)
   print(f"Received from {addr}: {data.decode()}")
   sock.close()
   ```

   ```python
   # udp_sender.py
   import socket

   sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   sock.sendto(b"Hello via UDP", ("127.0.0.1", 9998))
   print("Sent datagram")
   sock.close()
   ```

   ```bash
   python3 udp_receiver.py &
   python3 udp_sender.py
   ```

4. **Observe sockets from the OS**

   ```bash
   # Start the echo server
   python3 echo_server.py &
   SERVER_PID=$!

   # See the listening socket
   lsof -i :9999 -n -P

   # Connect a client
   nc localhost 9999 &

   # See LISTEN and ESTABLISHED
   lsof -i :9999 -n -P

   kill $SERVER_PID
   ```

### Checkpoint

Run the echo server. Connect with both the Python client and `nc`. Use
`lsof -i :9999` to see the listening and established sockets. Explain the
difference between SOCK_STREAM and SOCK_DGRAM.

---

## Lesson 6: Network Debugging

**Goal:** Diagnose network problems systematically using standard tools.

### Concepts

Network debugging works bottom-up: start at the link layer (is the interface
up?), then check IP connectivity (can you ping?), then routing (does the path
exist?), then DNS (does the name resolve?), then the application layer (does the
service respond?). `ping` tests reachability. `traceroute` maps the path. `mtr`
combines both with continuous monitoring. High latency suggests congestion or
distance; packet loss suggests a failing link or overloaded router.

### Exercises

1. **Test reachability and measure latency**

   ```bash
   # Ping a host -- measure round-trip time
   ping -c 5 google.com

   # Ping with a specific packet size
   ping -c 3 -s 1400 google.com

   # Note: avg RTT, min/max/stddev, packet loss %
   ```

2. **Trace the route to a host**

   ```bash
   # See every hop between you and the destination
   traceroute example.com

   # Use mtr for continuous monitoring (brew install mtr)
   sudo mtr -c 10 --report example.com
   # Look for hops with high loss or latency spikes
   ```

3. **Diagnose DNS and port connectivity**

   ```bash
   # Is DNS working?
   dig google.com +short
   # If this fails, your DNS server may be unreachable

   # Is the port open?
   nc -vz google.com 443
   # "Connection to google.com port 443 [tcp/https] succeeded!"

   # Is the port open but the service not responding?
   curl -v --connect-timeout 5 http://localhost:8080 2>&1
   ```

4. **Inspect active connections and listening services**

   ```bash
   # What is listening on this machine?
   lsof -i -n -P | grep LISTEN

   # What connections are active?
   netstat -an | grep ESTABLISHED | head -10

   # Which process owns a connection?
   lsof -i :443 -n -P

   # Check for TIME_WAIT buildup (sign of many short connections)
   netstat -an | grep TIME_WAIT | wc -l
   ```

### Checkpoint

Pick a website that loads slowly. Use `ping` to measure latency, `traceroute` to
identify which hop introduces the most delay, and `dig` to check if DNS
resolution is slow (compare `dig @8.8.8.8` against your default resolver). Write
a one-paragraph diagnosis.

---

## Lesson 7: Firewalls and Routing

**Goal:** Understand how packets find their destination and how firewalls
control what gets through.

### Concepts

Routing tables tell the OS where to send packets -- each entry maps a
destination network to a gateway and interface. The default route handles
anything not matched by a more specific rule. NAT (Network Address Translation)
lets multiple devices share one public IP by rewriting source addresses.
Firewalls filter packets by port, protocol, and address. On macOS, `pfctl`
manages the packet filter. SSH port forwarding creates encrypted tunnels through
firewalls.

### Exercises

1. **Examine your network interfaces and routing table**

   ```bash
   # List network interfaces
   ifconfig | grep -E "^[a-z]|inet "

   # Show the routing table
   netstat -rn | head -20

   # Find your default gateway
   netstat -rn | grep default

   # Show your public IP
   curl -s https://ifconfig.me
   ```

2. **Inspect macOS packet filter**

   ```bash
   # Check if pf is enabled
   sudo pfctl -s info 2>/dev/null | head -5

   # Show current filter rules
   sudo pfctl -s rules 2>/dev/null

   # Show current NAT rules
   sudo pfctl -s nat 2>/dev/null
   ```

3. **Set up SSH port forwarding**

   ```bash
   # Local forward: access remote_host:5432 via localhost:5432
   # ssh -L 5432:localhost:5432 user@remote_host

   # Example: forward a remote Postgres to local
   # ssh -L 5432:db.internal:5432 user@bastion.example.com
   # Then connect: psql -h localhost -p 5432

   # Dynamic SOCKS proxy
   # ssh -D 1080 user@remote_host
   # Configure your browser to use SOCKS5 proxy at localhost:1080

   # Test that a tunnel works (using a local service as demo)
   python3 -m http.server 8888 &
   SERVER_PID=$!
   # In a real scenario, this would be on a remote host
   # ssh -L 9000:localhost:8888 user@remote
   curl -s http://localhost:8888 | head -5
   kill $SERVER_PID
   ```

4. **Trace how NAT rewrites packets**

   ```bash
   # See your private IP
   ifconfig en0 | grep "inet "

   # See your public IP (after NAT)
   curl -s https://ifconfig.me

   # These differ because your router performs NAT
   # Private: 192.168.x.x or 10.x.x.x
   # Public: your ISP-assigned address

   # Check ARP table (link layer address resolution)
   arp -a | head -10
   ```

### Checkpoint

Print your routing table and identify the default gateway. Trace the path to an
external host with `traceroute` and confirm the first hop matches your gateway.
Set up an SSH local port forward and verify traffic passes through it.

---

## Lesson 8: Putting It Together

**Goal:** Combine every layer -- DNS, TCP, sockets, HTTP, debugging -- to build
a working networked application and diagnose it end to end.

### Concepts

A real network application touches every layer of the stack. The chat server in
this lesson uses sockets (transport), handles DNS resolution (application),
communicates over TCP (transport), and can be debugged with all the tools from
previous lessons. Building it yourself -- and then breaking it on purpose --
turns abstract layers into concrete, observable systems you can reason about
under pressure.

### Exercises

1. **Build a multi-client chat server**

   ```python
   # chat_server.py
   import socket, threading

   clients = []
   lock = threading.Lock()

   def broadcast(message, sender):
       with lock:
           for client in clients:
               if client != sender:
                   try:
                       client.sendall(message)
                   except:
                       clients.remove(client)

   def handle_client(conn, addr):
       print(f"[+] {addr} connected")
       with lock:
           clients.append(conn)
       broadcast(f"[{addr}] joined\n".encode(), conn)
       try:
           while True:
               data = conn.recv(1024)
               if not data:
                   break
               broadcast(f"[{addr}] {data.decode()}".encode(), conn)
       finally:
           with lock:
               clients.remove(conn)
           broadcast(f"[{addr}] left\n".encode(), conn)
           conn.close()
           print(f"[-] {addr} disconnected")

   server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
   server.bind(("127.0.0.1", 9999))
   server.listen(5)
   print("Chat server on 127.0.0.1:9999")

   while True:
       conn, addr = server.accept()
       threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
   ```

   ```bash
   python3 chat_server.py &
   # Open two terminals and connect:
   nc localhost 9999
   # Type messages -- they appear in the other terminal
   ```

2. **Add DNS resolution to the server**

   ```python
   # dns_resolve.py
   import socket

   def resolve_and_connect(hostname, port):
       """Resolve hostname and show what happens at each step."""
       print(f"Resolving {hostname}...")
       results = socket.getaddrinfo(hostname, port, socket.AF_INET, socket.SOCK_STREAM)
       for family, socktype, proto, canonname, sockaddr in results:
           print(f"  -> {sockaddr[0]}:{sockaddr[1]}")

       ip = results[0][4][0]
       print(f"Connecting to {ip}:{port}...")
       sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
       sock.settimeout(5)
       sock.connect((ip, port))
       print("Connected!")
       return sock

   sock = resolve_and_connect("example.com", 80)
   sock.sendall(b"GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n")
   response = sock.recv(4096)
   print(response.decode()[:200])
   sock.close()
   ```

   ```bash
   python3 dns_resolve.py
   ```

3. **Diagnose the chat server under load**

   ```bash
   # Start the chat server
   python3 chat_server.py &
   SERVER_PID=$!

   # Check it is listening
   lsof -i :9999 -n -P

   # Connect several clients
   for i in 1 2 3; do
     echo "hello from client $i" | nc -w 1 localhost 9999 &
   done
   sleep 2

   # Observe connections
   lsof -i :9999 -n -P
   netstat -an | grep 9999

   # Check the server process
   ps -o pid,rss,vsz,%cpu -p $SERVER_PID

   kill $SERVER_PID
   ```

4. **End-to-end debugging exercise**

   ```bash
   # Simulate diagnosing a "can't connect" problem:

   # 1. Is the network up?
   ping -c 2 8.8.8.8

   # 2. Does DNS work?
   dig example.com +short

   # 3. Is the port reachable?
   nc -vz example.com 80

   # 4. Does the service respond?
   curl -v --connect-timeout 5 http://example.com 2>&1 | head -15

   # 5. What does the local side show?
   lsof -i -n -P | grep -E "ESTABLISHED|SYN_SENT" | head -5

   # Practice: start the chat server on the wrong port (9998)
   # and methodically figure out why nc localhost 9999 fails
   ```

### Checkpoint

Start the chat server with two clients connected. Use `lsof`, `netstat`, and
`ps` to observe every socket, connection state, and thread. Then kill the server
process and describe what each client sees and what happens to the TCP
connections (hint: check for CLOSE_WAIT and TIME_WAIT states).

---

## Practice Projects

### Project 1: Port Scanner

Write a Python script that scans a range of ports on a target host using
sockets. Report which ports are open, measure connection time for each, and
identify the service name using `socket.getservbyport()`. Add a `--timeout` flag
and use threading to scan multiple ports concurrently.

### Project 2: DNS Monitoring Tool

Build a script that periodically resolves a list of domains and logs changes --
new IP addresses, TTL shifts, or failed lookups. Compare results from multiple
DNS servers (e.g., `8.8.8.8`, `1.1.1.1`, your ISP). Alert when a domain's
resolution differs between servers.

### Project 3: Network Diagnostic Dashboard

Combine `ping`, `traceroute`, `dig`, and `lsof` into a single Python script that
produces a one-page health report for a target host. Include: DNS resolution
time, TCP connection time, route hops, packet loss percentage, and active
connections. Output the report as formatted text to the terminal.

---

## Quick Reference

| Topic            | Key Commands                                             |
| ---------------- | -------------------------------------------------------- |
| Network stack    | `curl -v`, `ifconfig`, `traceroute`                      |
| DNS              | `dig`, `nslookup`, `dscacheutil`, `/etc/hosts`           |
| TCP/UDP          | `nc`, `lsof -i`, `netstat -an`                           |
| HTTP             | `curl -v`, `curl -sI`, `nc` (raw HTTP)                   |
| Sockets          | `socket.socket()`, `bind`, `listen`, `accept`, `connect` |
| Debugging        | `ping`, `traceroute`, `mtr`, `lsof -i`, `netstat`        |
| Firewalls/Routes | `netstat -rn`, `pfctl`, `ssh -L`, `arp -a`               |
| Full stack       | Combine all of the above to trace a request end to end   |

## See Also

- [HTTP Cheatsheet](../how/http.md) -- HTTP methods, status codes, and curl
  patterns
- [Unix Cheatsheet](../how/unix.md) -- Shell tools used throughout these lessons
- [Cryptography Lesson Plan](cryptography-lesson-plan.md) -- TLS builds on the
  network layer
- [Operating Systems Lesson Plan](operating-systems-lesson-plan.md) -- Processes
  and I/O underpin networking
